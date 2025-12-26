;; Pair (constant-product AMM) - basic implementation
;; NOTE: This is an educational scaffold. Audit before mainnet.

(define-data-var reserve-a uint u0)
(define-data-var reserve-b uint u0)
(define-data-var total-lp uint u0)

(define-map lp-balances (tuple (owner principal)) (tuple (balance uint)))

(define-constant FEE_NUM u3) ;; 0.3% fee numerator (i.e. fee multiplier 997/1000)
(define-constant FEE_DEN u1000)
(define-constant FEE_MULTIPLIER u997) ;; 1000 - 3 = 997

(define-read-only (get-reserves)
  (ok (tuple (reserve-a (var-get reserve-a)) (reserve-b (var-get reserve-b)))))

(define-read-only (lp-balance-of (owner principal))
  (match (map-get? lp-balances (tuple (owner owner)))
    bal (ok (get balance bal))
    (ok u0)))

(define-public (initialize (amount-a uint) (amount-b uint))
  (begin
    (var-set reserve-a amount-a)
    (var-set reserve-b amount-b)
    ;; initial LP = sqrt(amount-a * amount-b) simplified to min for simplicity
    (let ((initial-lp (if (> amount-a amount-b) amount-b amount-a)))
      (var-set total-lp initial-lp)
      (map-set lp-balances (tuple (owner tx-sender)) (tuple (balance initial-lp)))
      (ok initial-lp))))

(define-private (calc-out (amount-in uint) (reserve-in uint) (reserve-out uint))
  (let ((amount-in-with-fee (/ (* amount-in FEE_MULTIPLIER) u1000)))
    (let ((numerator (* amount-in-with-fee reserve-out))
          (denom (+ (* reserve-in u1000) amount-in-with-fee)))
      (if (is-eq denom u0)
        (err (err "divide-by-zero"))
        (ok (/ numerator denom))))))

(define-public (swap-a-for-b (amount-in uint) (min-amount-out uint))
  (let ((reserve-a (var-get reserve-a))
        (reserve-b (var-get reserve-b)))
    (match (calc-out amount-in reserve-a reserve-b)
      out
        (begin
          (if (< out min-amount-out)
            (err (err "slippage"))
            (begin
              (var-set reserve-a (+ reserve-a amount-in))
              (var-set reserve-b (- reserve-b out))
              (ok out))))
      err (err err))))

(define-public (mint-liquidity (amount-a uint) (amount-b uint))
  (let ((reserve-a (var-get reserve-a))
        (reserve-b (var-get reserve-b))
        (total-lp (var-get total-lp)))
    (if (or (is-eq reserve-a u0) (is-eq reserve-b u0))
      (err (err "pool-not-initialized"))
      (let ((lp-minted (min (/ (* amount-a total-lp) reserve-a)
                           (/ (* amount-b total-lp) reserve-b))))
        (var-set reserve-a (+ reserve-a amount-a))
        (var-set reserve-b (+ reserve-b amount-b))
        (var-set total-lp (+ total-lp lp-minted))
        (match (map-get? lp-balances (tuple (owner tx-sender)))
          bal
            (map-set lp-balances (tuple (owner tx-sender)) (tuple (balance (+ (get balance bal) lp-minted))))
          none
            (map-set lp-balances (tuple (owner tx-sender)) (tuple (balance lp-minted))))
        (ok lp-minted)))))

(define-public (burn-liquidity (lp-amount uint))
  (let ((reserve-a (var-get reserve-a))
        (reserve-b (var-get reserve-b))
        (total-lp (var-get total-lp)))
    (if (is-eq total-lp u0)
      (err (err "no-liquidity"))
      (let ((amount-a (/ (* lp-amount reserve-a) total-lp))
            (amount-b (/ (* lp-amount reserve-b) total-lp)))
        (var-set reserve-a (- reserve-a amount-a))
        (var-set reserve-b (- reserve-b amount-b))
        (var-set total-lp (- total-lp lp-amount))
        (match (map-get? lp-balances (tuple (owner tx-sender)))
          bal
            (let ((current (get balance bal)))
              (if (< current lp-amount)
                (err (err "insufficient-lp"))
                (map-set lp-balances (tuple (owner tx-sender)) (tuple (balance (- current lp-amount))))))
          none
            (err (err "no-lp")))
        (ok (tuple (amount-a amount-a) (amount-b amount-b)))))))
