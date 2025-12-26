;; factory.clar
;; Simple registry to map token pairs to deployed pair contract principals.

(define-map pairs
  (tuple (token-a (buff 34)) (token-b (buff 34)))
  (tuple (pair-owner principal) (pair-contract principal)))

(define-public (create-pair (token-a (buff 34)) (token-b (buff 34)) (pair-contract principal))
  (begin
    (map-set pairs (tuple (token-a token-a) (token-b token-b))
             (tuple (pair-owner tx-sender) (pair-contract pair-contract)))
    (ok true)))

(define-read-only (get-pair (token-a (buff 34)) (token-b (buff 34)))
  (match (map-get? pairs (tuple (token-a token-a) (token-b token-b)))
    pair (ok pair)
    none (err (err "pair-not-found"))))
;; Factory contract (basic) - creates & registers pair contracts

(define-map pairs
  (tuple (token-a (buff 34)) (token-b (buff 34)))
  (tuple (pair-owner principal) (pair-contract principal)))

(define-public (create-pair (token-a (buff 34)) (token-b (buff 34)) (pair-contract principal))
  (begin
    (map-set pairs (tuple (token-a token-a) (token-b token-b))
             (tuple (pair-owner tx-sender) (pair-contract pair-contract)))
    (ok true)))

(define-read-only (get-pair (token-a (buff 34)) (token-b (buff 34)))
  (match (map-get? pairs (tuple (token-a token-a) (token-b token-b)))
    pair (ok pair)
    (err (err "pair-not-found"))))
