;; faucet.clar
;; Simple token faucet for testnet development
;; Dispenses test tokens with cooldown period

(define-fungible-token test-token)

(define-constant FAUCET_AMOUNT u1000000) ;; 1M tokens per claim
(define-constant COOLDOWN_BLOCKS u144) ;; ~24 hours (assuming 10min blocks)
(define-constant ERR_TOO_SOON "cooldown-active")
(define-constant ERR_ZERO_AMOUNT "zero-amount")

(define-map last-claim principal uint)

;; --- Initialize faucet supply ---
(define-public (init-faucet)
  (ft-mint? test-token u1000000000000 tx-sender)) ;; Mint 1T tokens to contract deployer

;; --- Claim tokens ---
(define-public (claim)
  (let ((last-block (default-to u0 (map-get? last-claim tx-sender)))
        (current-block block-height))
    (if (>= current-block (+ last-block COOLDOWN_BLOCKS))
      (begin
        (map-set last-claim tx-sender current-block)
        (ft-mint? test-token FAUCET_AMOUNT tx-sender))
      (err ERR_TOO_SOON))))

;; --- Read-only helpers ---
(define-read-only (get-balance (account principal))
  (ok (ft-get-balance test-token account)))

(define-read-only (get-last-claim (account principal))
  (ok (default-to u0 (map-get? last-claim account))))

(define-read-only (blocks-until-next-claim (account principal))
  (let ((last-block (default-to u0 (map-get? last-claim account)))
        (current-block block-height)
        (next-claim (+ last-block COOLDOWN_BLOCKS)))
    (if (>= current-block next-claim)
      (ok u0)
      (ok (- next-claim current-block)))))

;; --- SIP-010 trait implementation ---
(define-read-only (get-name)
  (ok "Test Token"))

(define-read-only (get-symbol)
  (ok "TEST"))

(define-read-only (get-decimals)
  (ok u6))

(define-read-only (get-total-supply)
  (ok (ft-get-supply test-token)))

(define-read-only (get-token-uri)
  (ok (some u"https://claryswap.example/test-token")))

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    (asserts! (is-eq tx-sender sender) (err "unauthorized"))
    (ft-transfer? test-token amount sender recipient)))
