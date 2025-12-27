;; pair-v2.clar
;; Enhanced constant-product AMM with security features:
;; - Pausable functionality
;; - Owner/admin controls
;; - Configurable fee (within bounds)
;; - Reentrancy-safe patterns (checks-effects-interactions)

(define-data-var reserve-a uint u0)
(define-data-var reserve-b uint u0)
(define-data-var total-lp uint u0)
(define-data-var owner principal tx-sender)
(define-data-var paused bool false)
(define-data-var fee-multiplier uint u997) ;; Default 0.3% fee (997/1000)
(define-data-var fee-to (optional principal) none) ;; Protocol fee recipient

(define-map lp-balances (tuple (owner principal)) (tuple (balance uint)))

(define-constant ERR_PAUSED "contract-paused")
(define-constant ERR_UNAUTHORIZED "unauthorized")
(define-constant ERR_INVALID_FEE "invalid-fee")
(define-constant ERR_ZERO_AMOUNT "zero-amount")
(define-constant ERR_INSUFFICIENT "insufficient-balance")
(define-constant MIN_FEE u990) ;; Max 1% fee
(define-constant MAX_FEE u999) ;; Min 0.1% fee

;; --- Access control ---
(define-read-only (is-owner)
  (is-eq tx-sender (var-get owner)))

(define-public (transfer-ownership (new-owner principal))
  (if (is-owner)
    (ok (var-set owner new-owner))
    (err ERR_UNAUTHORIZED)))

;; --- Pausable ---
(define-public (pause)
  (if (is-owner)
    (ok (var-set paused true))
    (err ERR_UNAUTHORIZED)))

(define-public (unpause)
  (if (is-owner)
    (ok (var-set paused false))
    (err ERR_UNAUTHORIZED)))

(define-read-only (is-paused)
  (ok (var-get paused)))

;; --- Fee configuration ---
(define-public (set-fee (new-fee uint))
  (if (is-owner)
    (if (and (>= new-fee MIN_FEE) (<= new-fee MAX_FEE))
      (ok (var-set fee-multiplier new-fee))
      (err ERR_INVALID_FEE))
    (err ERR_UNAUTHORIZED)))

(define-public (set-fee-to (recipient (optional principal)))
  (if (is-owner)
    (ok (var-set fee-to recipient))
    (err ERR_UNAUTHORIZED)))

(define-read-only (get-fee-config)
  (ok (tuple (fee-multiplier (var-get fee-multiplier)) (fee-to (var-get fee-to)))))

;; --- Read-only helpers ---
(define-read-only (get-reserves)
  (ok (tuple (reserve-a (var-get reserve-a)) (reserve-b (var-get reserve-b)))))

(define-read-only (lp-balance-of (owner principal))
  (match (map-get? lp-balances (tuple (owner owner)))
    bal (ok (get balance bal))
    none (ok u0)))

;; --- Internal helpers ---
(define-private (min (a uint) (b uint)) (if (< a b) a b))

(define-private (calc-out (amount-in uint) (reserve-in uint) (reserve-out uint))
  (if (or (is-eq amount-in u0) (is-eq reserve-in u0) (is-eq reserve-out u0))
    (err ERR_ZERO_AMOUNT)
    (let ((fee (var-get fee-multiplier))
          (amount-in-with-fee (/ (* amount-in fee) u1000)))
      (let ((numerator (* amount-in-with-fee reserve-out))
            (denom (+ reserve-in amount-in-with-fee)))
        (ok (/ numerator denom))))))

;; --- Lifecycle (with pause checks) ---
(define-public (initialize (amount-a uint) (amount-b uint))
  (if (var-get paused)
    (err ERR_PAUSED)
    (if (or (is-eq (var-get reserve-a) u0) (is-eq (var-get reserve-b) u0))
      (if (or (is-eq amount-a u0) (is-eq amount-b u0))
        (err ERR_ZERO_AMOUNT)
        (let ((initial-lp (min amount-a amount-b)))
          (var-set reserve-a amount-a)
          (var-set reserve-b amount-b)
          (var-set total-lp initial-lp)
          (map-set lp-balances (tuple (owner tx-sender)) (tuple (balance initial-lp)))
          (ok initial-lp)))
      (err "already-initialized"))))

(define-public (mint-liquidity (amount-a uint) (amount-b uint))
  (if (var-get paused)
    (err ERR_PAUSED)
    (let ((reserve-a (var-get reserve-a))
          (reserve-b (var-get reserve-b))
          (total (var-get total-lp)))
      (if (or (is-eq reserve-a u0) (is-eq reserve-b u0))
        (err "pool-not-initialized")
        (let ((to-mint (min (/ (* amount-a total) reserve-a)
                             (/ (* amount-b total) reserve-b))))
          (if (is-eq to-mint u0)
            (err ERR_ZERO_AMOUNT)
            (begin
              (var-set reserve-a (+ reserve-a amount-a))
              (var-set reserve-b (+ reserve-b amount-b))
              (var-set total-lp (+ total to-mint))
              (match (map-get? lp-balances (tuple (owner tx-sender)))
                bal
                  (map-set lp-balances (tuple (owner tx-sender)) (tuple (balance (+ (get balance bal) to-mint))))
                none
                  (map-set lp-balances (tuple (owner tx-sender)) (tuple (balance to-mint))))
              (ok to-mint))))))))

(define-public (burn-liquidity (lp-amount uint))
  (if (var-get paused)
    (err ERR_PAUSED)
    (let ((reserve-a (var-get reserve-a))
          (reserve-b (var-get reserve-b))
          (total (var-get total-lp)))
      (if (or (is-eq total u0) (is-eq lp-amount u0))
        (err ERR_ZERO_AMOUNT)
        (let ((amount-a (/ (* lp-amount reserve-a) total))
              (amount-b (/ (* lp-amount reserve-b) total)))
          (match (map-get? lp-balances (tuple (owner tx-sender)))
            bal
              (let ((current (get balance bal)))
                (if (< current lp-amount)
                  (err ERR_INSUFFICIENT)
                  (begin
                    (var-set reserve-a (- reserve-a amount-a))
                    (var-set reserve-b (- reserve-b amount-b))
                    (var-set total-lp (- total lp-amount))
                    (map-set lp-balances (tuple (owner tx-sender)) (tuple (balance (- current lp-amount))))
                    (ok (tuple (amount-a amount-a) (amount-b amount-b))))))
            none (err ERR_INSUFFICIENT)))))))

;; --- Swap functions ---
(define-public (swap-a-for-b (amount-in uint) (min-out uint))
  (if (var-get paused)
    (err ERR_PAUSED)
    (let ((reserve-a (var-get reserve-a))
          (reserve-b (var-get reserve-b)))
      (match (calc-out amount-in reserve-a reserve-b)
        amount-out
          (if (< amount-out min-out)
            (err "slippage-exceeded")
            (begin
              (var-set reserve-a (+ reserve-a amount-in))
              (var-set reserve-b (- reserve-b amount-out))
              (ok amount-out)))
        err-val (err err-val)))))

(define-public (swap-b-for-a (amount-in uint) (min-out uint))
  (if (var-get paused)
    (err ERR_PAUSED)
    (let ((reserve-a (var-get reserve-a))
          (reserve-b (var-get reserve-b)))
      (match (calc-out amount-in reserve-b reserve-a)
        amount-out
          (if (< amount-out min-out)
            (err "slippage-exceeded")
            (begin
              (var-set reserve-b (+ reserve-b amount-in))
              (var-set reserve-a (- reserve-a amount-out))
              (ok amount-out)))
        err-val (err err-val)))))
