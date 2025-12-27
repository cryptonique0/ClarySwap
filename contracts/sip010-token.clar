;; sip010-token.clar
;; Reference SIP-010 fungible token trait for integration testing
;; This is a minimal example token contract implementing the SIP-010 standard

(define-fungible-token test-token)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-insufficient-balance (err u102))

;; SIP-010 trait implementation
(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    (asserts! (is-eq tx-sender sender) err-not-token-owner)
    (try! (ft-transfer? test-token amount sender recipient))
    (match memo to-print (print to-print) 0x)
    (ok true)))

(define-read-only (get-name)
  (ok "Test Token"))

(define-read-only (get-symbol)
  (ok "TEST"))

(define-read-only (get-decimals)
  (ok u6))

(define-read-only (get-balance (who principal))
  (ok (ft-get-balance test-token who)))

(define-read-only (get-total-supply)
  (ok (ft-get-supply test-token)))

(define-read-only (get-token-uri)
  (ok none))

;; Mint function for testing (owner only)
(define-public (mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ft-mint? test-token amount recipient)))

;; Initialize with some supply for testing
(begin
  (try! (ft-mint? test-token u1000000000000 contract-owner))
  (ok true))
