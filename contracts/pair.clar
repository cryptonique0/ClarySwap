;; pair.clar
;; Constant-product AMM pair with internal LP accounting.
;; NOTE: Educational scaffold. Audit before production use.

(define-data-var reserve-a uint u0)
(define-data-var reserve-b uint u0)
(define-data-var total-lp uint u0)

(define-map lp-balances (tuple (owner principal)) (tuple (balance uint)))

(define-constant FEE_MULTIPLIER u997) ;; 0.3% fee => 997/1000

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
    (err "invalid-input")
    (let ((amount-in-with-fee (/ (* amount-in FEE_MULTIPLIER) u1000)))
      (let ((numerator (* amount-in-with-fee reserve-out))
            (denom (+ reserve-in amount-in-with-fee)))
        (ok (/ numerator denom))))))

;; --- Lifecycle ---
(define-public (initialize (amount-a uint) (amount-b uint))
  (if (or (is-eq (var-get reserve-a) u0) (is-eq (var-get reserve-b) u0))
    (if (or (is-eq amount-a u0) (is-eq amount-b u0))
      (err "zero-amount")
      (let ((initial-lp (min amount-a amount-b)))
        (var-set reserve-a amount-a)
        (var-set reserve-b amount-b)
        (var-set total-lp initial-lp)
        (map-set lp-balances (tuple (owner tx-sender)) (tuple (balance initial-lp)))
        (ok initial-lp)))
    (err "already-initialized")))

(define-public (mint-liquidity (amount-a uint) (amount-b uint))
  (let ((reserve-a (var-get reserve-a))
        (reserve-b (var-get reserve-b))
        (total (var-get total-lp)))
    (if (or (is-eq reserve-a u0) (is-eq reserve-b u0))
      (err "pool-not-initialized")
      (let ((to-mint (min (/ (* amount-a total) reserve-a)
                           (/ (* amount-b total) reserve-b))))
        (if (is-eq to-mint u0)
          (err "zero-liquidity")
          (begin
            (var-set reserve-a (+ reserve-a amount-a))
            (var-set reserve-b (+ reserve-b amount-b))
            (var-set total-lp (+ total to-mint))
            (match (map-get? lp-balances (tuple (owner tx-sender)))
              bal
                (map-set lp-balances (tuple (owner tx-sender)) (tuple (balance (+ (get balance bal) to-mint))))
              none
                (map-set lp-balances (tuple (owner tx-sender)) (tuple (balance to-mint))))
            (ok to-mint)))))))

(define-public (burn-liquidity (lp-amount uint))
  (let ((reserve-a (var-get reserve-a))
        (reserve-b (var-get reserve-b))
        (total (var-get total-lp)))
    (if (or (is-eq total u0) (is-eq lp-amount u0))
      (err "invalid-burn")
      (let ((amount-a (/ (* lp-amount reserve-a) total))
            (amount-b (/ (* lp-amount reserve-b) total)))
        (match (map-get? lp-balances (tuple (owner tx-sender)))
          bal
            (let ((current (get balance bal)))
              (if (< current lp-amount)
                (err "insufficient-lp")
                (begin
                  (map-set lp-balances (tuple (owner tx-sender)) (tuple (balance (- current lp-amount))))
                  (var-set reserve-a (- reserve-a amount-a))
                  (var-set reserve-b (- reserve-b amount-b))
                  (var-set total-lp (- total lp-amount))
                  (ok (tuple (amount-a amount-a) (amount-b amount-b))))))
          none (err "no-lp"))))))

(define-public (swap-a-for-b (amount-in uint) (min-amount-out uint))
  (let ((reserve-a (var-get reserve-a))
        (reserve-b (var-get reserve-b)))
    (match (calc-out amount-in reserve-a reserve-b)
      out
        (if (< out min-amount-out)
          (err "slippage")
          (begin
            (var-set reserve-a (+ reserve-a amount-in))
            (var-set reserve-b (- reserve-b out))
            (ok out)))
      err (err err))))

(define-public (swap-b-for-a (amount-in uint) (min-amount-out uint))
  (let ((reserve-a (var-get reserve-a))
        (reserve-b (var-get reserve-b)))
    (match (calc-out amount-in reserve-b reserve-a)
      out
        (if (< out min-amount-out)
          (err "slippage")
          (begin
            (var-set reserve-b (+ reserve-b amount-in))
            (var-set reserve-a (- reserve-a out))
            (ok out)))
      err (err err))))
