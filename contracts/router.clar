;; router.clar
;; Router that can perform single-hop swaps by calling pair contracts.
;; Multi-hop routing can be built on top of this by chaining swap calls.

(define-read-only (quote-simple)
  (ok "router stub"))

(define-public (swap-single-hop (pair-contract principal) (a-to-b bool) (amount-in uint) (min-amount-out uint))
  (if a-to-b
    (contract-call? pair-contract swap-a-for-b amount-in min-amount-out)
    (contract-call? pair-contract swap-b-for-a amount-in min-amount-out)) )
