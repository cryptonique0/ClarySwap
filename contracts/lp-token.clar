;; lp-token.clar
;; Minimal SIP-like fungible token for LP tokens (developer/test use).
;; WARNING: `mint` and `burn` are callable by any principal in this scaffold.
;; Restrict access (owner/minter roles) before production use.

(define-data-var total-supply uint u0)
(define-map balances (tuple (owner principal)) (tuple (balance uint)))
(define-map allowances (tuple (owner principal) (spender principal)) (tuple (amount uint)))

;; Minter control
(define-data-var minter principal 'ST000000000000000000002AMM)
(define-data-var minter-set bool false)

(define-read-only (name) (ok (buff "Clary LP Token")))
(define-read-only (symbol) (ok (buff "CLP")))
(define-read-only (decimals) (ok u6))
(define-read-only (total-supply) (ok (var-get total-supply)))

(define-read-only (balance-of (owner principal))
  (match (map-get? balances (tuple (owner owner)))
    b (ok (get balance b))
    none (ok u0)))

(define-public (transfer (recipient principal) (amount uint))
  (let ((sender tx-sender))
    (match (map-get? balances (tuple (owner sender)))
      bal
        (let ((current (get balance bal)))
          (if (< current amount)
            (err (err "insufficient-balance"))
            (begin
              (map-set balances (tuple (owner sender)) (tuple (balance (- current amount))))
              (match (map-get? balances (tuple (owner recipient)))
                rbal
                  (map-set balances (tuple (owner recipient)) (tuple (balance (+ (get balance rbal) amount))))
                none
                  (map-set balances (tuple (owner recipient)) (tuple (balance amount))))
              (ok true)))))
      none (err (err "insufficient-balance")))))

(define-public (approve (spender principal) (amount uint))
  (begin
    (map-set allowances (tuple (owner tx-sender) (spender spender)) (tuple (amount amount)))
    (ok true)))

(define-public (transfer-from (owner principal) (recipient principal) (amount uint))
  (let ((spender tx-sender))
    (match (map-get? allowances (tuple (owner owner) (spender spender)))
      a
        (let ((allowed (get amount a)))
          (if (< allowed amount)
            (err (err "insufficient-allowance"))
            (match (map-get? balances (tuple (owner owner)))
              bal
                (let ((current (get balance bal)))
                  (if (< current amount)
                    (err (err "insufficient-balance"))
                    (begin
                      (map-set balances (tuple (owner owner)) (tuple (balance (- current amount))))
                      (match (map-get? balances (tuple (owner recipient)))
                        rbal
                          (map-set balances (tuple (owner recipient)) (tuple (balance (+ (get balance rbal) amount))))
                        none
                          (map-set balances (tuple (owner recipient)) (tuple (balance amount))))
                      (map-set allowances (tuple (owner owner) (spender spender)) (tuple (amount (- allowed amount))))
                      (ok true)))))
              none (err (err "insufficient-balance")))))
      none (err (err "insufficient-allowance")))))

;; Mint: increases total-supply and recipient balance
;; Only the designated minter can mint
(define-public (set-minter (m principal))
  (let ((is-set (var-get minter-set)))
    (if (is-eq is-set false)
      (begin
        (var-set minter m)
        (var-set minter-set true)
        (ok true))
      (if (is-eq tx-sender (var-get minter))
        (begin (var-set minter m) (ok true))
        (err (err "unauthorized"))))))

(define-public (mint (to principal) (amount uint))
  (if (is-eq tx-sender (var-get minter))
    (begin
      (var-set total-supply (+ (var-get total-supply) amount))
      (match (map-get? balances (tuple (owner to)))
        b
          (map-set balances (tuple (owner to)) (tuple (balance (+ (get balance b) amount))))
        none
          (map-set balances (tuple (owner to)) (tuple (balance amount))))
      (ok true))
    (err (err "unauthorized"))))

;; Burn: decreases total-supply and holder balance
;; Only the minter can burn (burning will be requested by pair contract)
(define-public (burn (from principal) (amount uint))
  (if (is-eq tx-sender (var-get minter))
    (match (map-get? balances (tuple (owner from)))
      b
        (let ((current (get balance b)) (total (var-get total-supply)))
          (if (< current amount)
            (err (err "insufficient-balance"))
            (begin
              (map-set balances (tuple (owner from)) (tuple (balance (- current amount))))
              (var-set total-supply (- total amount))
              (ok true))))
      none (err (err "insufficient-balance")))
    (err (err "unauthorized"))))
