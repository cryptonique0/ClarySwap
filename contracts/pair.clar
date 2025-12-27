;; pair.clar
;; Constant-product AMM pair contract that delegates LP mint/burn to an external LP token contract.
;; Owner can set the `lp-token` principal once (or later if owner calls).
;; NOTE: This is a scaffold for development and testing. Audit before production.

;; Owner of this pair (set on initialize)
(define-data-var owner principal 'ST000000000000000000002AMM)

;; LP token contract principal (set by owner via `set-lp-token`)
(define-data-var lp-token principal 'ST000000000000000000002AMM)

;; Reserves and LP total tracked locally; token balances are maintained in LP token contract.
(define-data-var reserve-a uint u0)
(define-data-var reserve-b uint u0)
(define-data-var total-lp uint u0)

;; Fee settings: 0.3% fee (997/1000)
(define-constant FEE_NUM u997)
(define-constant FEE_DEN u1000)

;; --- Read-only helpers ---
(define-read-only (get-reserves)
  (ok (tuple (reserve-a (var-get reserve-a)) (reserve-b (var-get reserve-b)))))

(define-read-only (get-lp-token)
  (ok (var-get lp-token)))

(define-read-only (get-owner)
  (ok (var-get owner)))

(define-read-only (total-supply)
  (ok (var-get total-lp)))

;; --- Owner controls ---
(define-public (set-lp-token (token principal))
  (begin
    (if (is-eq tx-sender (var-get owner))
      (begin
        (var-set lp-token token)
        (ok true))
      (err (err "unauthorized")))))

;; --- Internal math helpers ---
(define-private (min (a uint) (b uint)) (if (< a b) a b))

;; Compute output amount using constant-product and fee
(define-private (get-amount-out (amount-in uint) (reserve-in uint) (reserve-out uint))
  (if (or (is-eq amount-in u0) (is-eq reserve-in u0) (is-eq reserve-out u0))
    (err (err "invalid-input"))
    (let ((amount-in-with-fee (/ (* amount-in FEE_NUM) FEE_DEN)))
      (let ((numerator (* amount-in-with-fee reserve-out))
            (denom (+ reserve-in amount-in-with-fee)))
        (ok (/ numerator denom))))))

;; --- Pool lifecycle: initialize / mint / burn / swap ---

;; Initialize pool by first liquidity provider. Sets owner to initializer.
(define-public (initialize (amount-a uint) (amount-b uint))
  (if (or (is-eq (var-get reserve-a) u0) (is-eq (var-get reserve-b) u0))
    (if (or (is-eq amount-a u0) (is-eq amount-b u0))
      (err (err "zero-amount"))
      (let ((initial-lp (if (> amount-a amount-b) amount-b amount-a)))
        (var-set reserve-a amount-a)
        (var-set reserve-b amount-b)
        (var-set total-lp initial-lp)
        (var-set owner tx-sender)
        ;; Mint LP tokens to initializer via external LP token if set
        (match (contract-call? (var-get lp-token) mint tx-sender initial-lp)
          res (ok initial-lp)
          err (ok initial-lp))))
    (err (err "already-initialized"))))

;; Add liquidity: mint LP proportionally. Caller must transfer tokens to the pair beforehand via SIP-010 transfers.
(define-public (mint-liquidity (amount-a uint) (amount-b uint))
  (let ((reserve-a (var-get reserve-a))
        (reserve-b (var-get reserve-b))
        (total (var-get total-lp)))
    (if (or (is-eq reserve-a u0) (is-eq reserve-b u0))
      (err (err "pool-not-initialized"))
      (let ((lp-from-a (/ (* amount-a total) reserve-a))
            (lp-from-b (/ (* amount-b total) reserve-b))
            (to-mint (min (/ (* amount-a total) reserve-a) (/ (* amount-b total) reserve-b))))
        (if (is-eq to-mint u0)
          (err (err "zero-liquidity"))
          (begin
            (var-set reserve-a (+ reserve-a amount-a))
            (var-set reserve-b (+ reserve-b amount-b))
            (var-set total-lp (+ total to-mint))
            ;; Call external LP token mint
            (match (contract-call? (var-get lp-token) mint tx-sender to-mint)
              res (ok to-mint)
              err (err err)))))))

;; Remove liquidity: burn LP via LP token contract and return corresponding amounts.
(define-public (burn-liquidity (lp-amount uint) (to principal))
  (let ((reserve-a (var-get reserve-a))
        (reserve-b (var-get reserve-b))
        (total (var-get total-lp)))
    (if (or (is-eq total u0) (is-eq lp-amount u0))
      (err (err "invalid-burn"))
      (let ((amount-a (/ (* lp-amount reserve-a) total))
            (amount-b (/ (* lp-amount reserve-b) total)))
        ;; Burn LP tokens from caller (caller must have approved or use transfer-from pattern); pair will call burn on LP token
        (match (contract-call? (var-get lp-token) burn tx-sender lp-amount)
          res
            (begin
              (var-set reserve-a (- reserve-a amount-a))
              (var-set reserve-b (- reserve-b amount-b))
              (var-set total-lp (- total lp-amount))
              ;; In real implementation, transfer tokens to `to` via SIP-010 transfer calls
              (ok (tuple (amount-a amount-a) (amount-b amount-b))))
          err (err err))))))

;; Swap A -> B
(define-public (swap-a-for-b (amount-in uint) (min-amount-out uint))
  (let ((reserve-a (var-get reserve-a))
        (reserve-b (var-get reserve-b)))
    (match (get-amount-out amount-in reserve-a reserve-b)
      out
        (if (< out min-amount-out)
          (err (err "slippage"))
          (begin
            (var-set reserve-a (+ reserve-a amount-in))
            (var-set reserve-b (- reserve-b out))
            ;; In real implementation, perform SIP-010 transfers: take `amount-in` from caller and send `out` to caller
            (ok out)))
      err (err err))))

;; Swap B -> A
(define-public (swap-b-for-a (amount-in uint) (min-amount-out uint))
  (let ((reserve-a (var-get reserve-a))
        (reserve-b (var-get reserve-b)))
    (match (get-amount-out amount-in reserve-b reserve-a)
      out
        (if (< out min-amount-out)
          (err (err "slippage"))
          (begin
            (var-set reserve-b (+ reserve-b amount-in))
            (var-set reserve-a (- reserve-a out))
            (ok out)))
      err (err err))))
;; pair.clar
;; Constant-product AMM pair contract with embedded minimal LP token interface.
;; NOTE: This implementation is educational. Audit before mainnet use.
;; LP integration: this contract currently keeps internal LP accounting.
;; There's a separate `contracts/lp-token.clar` included (minimal SIP-like token).
;; To integrate external LP token, replace internal mint/burn calls with
;; `contract-call?` to the deployed LP token `mint`/`burn` functions,
;; and restrict minter permissions on the LP token contract.

(define-data-var reserve-a uint u0)
(define-data-var reserve-b uint u0)
(define-data-var total-lp uint u0)

(define-map lp-balances (tuple (owner principal)) (tuple (balance uint)))
(define-map allowances (tuple (owner principal) (spender principal)) (tuple (amount uint)))

;; Fee settings: 0.3% fee (997/1000)
(define-constant FEE_NUM u997)
(define-constant FEE_DEN u1000)

;; --- Read-only helpers ---
(define-read-only (get-reserves)
  (ok (tuple (reserve-a (var-get reserve-a)) (reserve-b (var-get reserve-b)))))

(define-read-only (total-supply)
  (ok (var-get total-lp)))

(define-read-only (balance-of (owner principal))
  (match (map-get? lp-balances (tuple (owner owner)))
    bal (ok (get balance bal))
    none (ok u0)))

(define-read-only (allowance (owner principal) (spender principal))
  (match (map-get? allowances (tuple (owner owner) (spender spender)))
    a (ok (get amount a))
    none (ok u0)))

;; --- Internal math helpers ---
(define-private (min (a uint) (b uint))
  (if (< a b) a b))

;; Compute output amount using constant-product and fee
(define-private (get-amount-out (amount-in uint) (reserve-in uint) (reserve-out uint))
  (if (or (is-eq amount-in u0) (is-eq reserve-in u0) (is-eq reserve-out u0))
    (err (err "invalid-input"))
    (let ((amount-in-with-fee (/ (* amount-in FEE_NUM) FEE_DEN)))
      (let ((numerator (* amount-in-with-fee reserve-out))
            (denom (+ reserve-in amount-in-with-fee)))
        (ok (/ numerator denom))))))

;; --- LP token interface (minimal SIP-like) ---
(define-public (transfer (recipient principal) (amount uint))
  (let ((sender tx-sender))
    (match (map-get? lp-balances (tuple (owner sender)))
      bal
        (let ((current (get balance bal)))
          (if (< current amount)
            (err (err "insufficient-balance"))
            (begin
              (map-set lp-balances (tuple (owner sender)) (tuple (balance (- current amount))))
              (match (map-get? lp-balances (tuple (owner recipient)))
                rbal
                  (map-set lp-balances (tuple (owner recipient)) (tuple (balance (+ (get balance rbal) amount))))
                none
                  (map-set lp-balances (tuple (owner recipient)) (tuple (balance amount))))
              (ok true))))
      none (err (err "insufficient-balance")))))

(define-public (approve (spender principal) (amount uint))
  (begin
    (map-set allowances (tuple (owner tx-sender) (spender spender)) (tuple (amount amount)))
    (ok true)))

(define-public (transfer-from (owner principal) (recipient principal) (amount uint))
  (let ((spender tx-sender))
    (match (map-get? allowances (tuple (owner owner) (spender spender)))
      allowance
        (let ((allowed (get amount allowance)))
          (if (< allowed amount)
            (err (err "insufficient-allowance"))
            (match (map-get? lp-balances (tuple (owner owner)))
              bal
                (let ((current (get balance bal)))
                  (if (< current amount)
                    (err (err "insufficient-balance"))
                    (begin
                      ;; decrease owner balance
                      (map-set lp-balances (tuple (owner owner)) (tuple (balance (- current amount))))
                      ;; increase recipient balance
                      (match (map-get? lp-balances (tuple (owner recipient)))
                        rbal
                          (map-set lp-balances (tuple (owner recipient)) (tuple (balance (+ (get balance rbal) amount))))
                        none
                          (map-set lp-balances (tuple (owner recipient)) (tuple (balance amount))))
                      ;; decrease allowance
                      (map-set allowances (tuple (owner owner) (spender spender)) (tuple (amount (- allowed amount))))
                      (ok true)))))
              none (err (err "insufficient-balance")))))
      none (err (err "insufficient-allowance")))))

;; Mint LP tokens (internal use)
(define-private (lp-mint (to principal) (amount uint))
  (var-set total-lp (+ (var-get total-lp) amount))
  (match (map-get? lp-balances (tuple (owner to)))
    bal
      (map-set lp-balances (tuple (owner to)) (tuple (balance (+ (get balance bal) amount))))
    none
      (map-set lp-balances (tuple (owner to)) (tuple (balance amount))))
  (ok true))

;; Burn LP tokens (internal use)
(define-private (lp-burn (from principal) (amount uint))
  (let ((total (var-get total-lp)))
    (if (< total amount)
      (err (err "burn-exceeds-total"))
      (match (map-get? lp-balances (tuple (owner from)))
        bal
          (let ((current (get balance bal)))
            (if (< current amount)
              (err (err "burn-exceeds-balance"))
              (begin
                (map-set lp-balances (tuple (owner from)) (tuple (balance (- current amount))))
                (var-set total-lp (- total amount))
                (ok true))))
        none (err (err "no-balance"))))))

;; --- Pool lifecycle: initialize / mint / burn / swap ---

;; Initialize pool by first liquidity provider.
(define-public (initialize (amount-a uint) (amount-b uint))
  (if (or (<= (var-get reserve-a) u0) (<= (var-get reserve-b) u0))
    (if (or (is-eq amount-a u0) (is-eq amount-b u0))
      (err (err "zero-amount"))
      (let ((minted (sqrt (* amount-a amount-b)))) ;; Note: sqrt not available; approximate using min for simplicity
        (var-set reserve-a amount-a)
        (var-set reserve-b amount-b)
        (var-set total-lp (if (> amount-a amount-b) amount-b amount-a))
        (map-set lp-balances (tuple (owner tx-sender)) (tuple (balance (var-get total-lp))))
        (ok (var-get total-lp))))
    (err (err "already-initialized"))))

;; Helper sqrt approximation (not precise)
(define-private (sqrt (x uint))
  (loop ((r u1) (i u0))
    (let ((nr (/ (+ r (/ x r)) u2)))
      (if (is-eq nr r) r (recur nr (+ i u1))))))

;; Add liquidity: mint LP proportionally
(define-public (mint-liquidity (amount-a uint) (amount-b uint))
  (let ((reserve-a (var-get reserve-a))
        (reserve-b (var-get reserve-b))
        (total (var-get total-lp)))
    (if (or (is-eq reserve-a u0) (is-eq reserve-b u0))
      (err (err "pool-not-initialized"))
      (let ((lp-from-a (/ (* amount-a total) reserve-a))
            (lp-from-b (/ (* amount-b total) reserve-b))
            (to-mint (min (/ (* amount-a total) reserve-a) (/ (* amount-b total) reserve-b))))
        (if (is-eq to-mint u0)
          (err (err "zero-liquidity"))
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

;; Remove liquidity: burn LP and return amounts
(define-public (burn-liquidity (lp-amount uint) (to principal))
  (let ((reserve-a (var-get reserve-a))
        (reserve-b (var-get reserve-b))
        (total (var-get total-lp)))
    (if (or (is-eq total u0) (is-eq lp-amount u0))
      (err (err "invalid-burn"))
      (let ((amount-a (/ (* lp-amount reserve-a) total))
            (amount-b (/ (* lp-amount reserve-b) total)))
        (match (lp-burn tx-sender lp-amount)
          (ok true)
            (begin
              (var-set reserve-a (- reserve-a amount-a))
              (var-set reserve-b (- reserve-b amount-b))
              ;; In real implementation, transfer tokens to `to` via SIP-010 transfer calls
              (ok (tuple (amount-a amount-a) (amount-b amount-b))))
          err (err err))))))

;; Swap A -> B
(define-public (swap-a-for-b (amount-in uint) (min-amount-out uint))
  (let ((reserve-a (var-get reserve-a))
        (reserve-b (var-get reserve-b)))
    (match (get-amount-out amount-in reserve-a reserve-b)
      out
        (if (< out min-amount-out)
          (err (err "slippage"))
          (begin
            (var-set reserve-a (+ reserve-a amount-in))
            (var-set reserve-b (- reserve-b out))
            ;; In real implementation, transfer tokens accordingly
            (ok out)))
      err (err err))))

;; Swap B -> A
(define-public (swap-b-for-a (amount-in uint) (min-amount-out uint))
  (let ((reserve-a (var-get reserve-a))
        (reserve-b (var-get reserve-b)))
    (match (get-amount-out amount-in reserve-b reserve-a)
      out
        (if (< out min-amount-out)
          (err (err "slippage"))
          (begin
            (var-set reserve-b (+ reserve-b amount-in))
            (var-set reserve-a (- reserve-a out))
            (ok out)))
      err (err err))))
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
