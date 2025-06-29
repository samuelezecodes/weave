;; Weave - Hardened NFT contract with comprehensive input validation
;; A secure digital art NFT marketplace with validated inputs and enhanced security

;; Define the NFT
(define-non-fungible-token secureart-marketplace uint)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-not-token-owner (err u301))
(define-constant err-token-not-found (err u302))
(define-constant err-metadata-frozen (err u303))
(define-constant err-mint-limit-exceeded (err u304))
(define-constant err-invalid-price (err u305))
(define-constant err-insufficient-funds (err u306))
(define-constant err-not-for-sale (err u307))
(define-constant err-invalid-royalty (err u308))
(define-constant err-invalid-input (err u309))
(define-constant err-invalid-string (err u310))
(define-constant err-zero-address (err u311))

;; Input validation constants
(define-constant max-title-length u64)
(define-constant max-description-length u512)
(define-constant max-url-length u256)
(define-constant max-category-length u32)
(define-constant max-name-length u64)
(define-constant max-bio-length u256)
(define-constant max-royalty-rate u1000) ;; 10%
(define-constant max-platform-fee u1000) ;; 10%

;; Data variables
(define-data-var last-token-id uint u0)
(define-data-var base-token-uri (string-ascii 256) "https://api.secureart.com/metadata/")
(define-data-var metadata-frozen bool false)
(define-data-var collection-limit uint u3000)
(define-data-var platform-fee-rate uint u200) ;; 2% in basis points
(define-data-var total-volume uint u0)
(define-data-var paused bool false)

;; Validated categories list
(define-data-var valid-categories (list 20 (string-ascii 32)) 
    (list "digital-art" "photography" "abstract" "portrait" "landscape" 
          "animation" "3d-art" "pixel-art" "vector-art" "mixed-media"
          "conceptual" "surreal" "minimalist" "pop-art" "street-art"
          "fantasy" "sci-fi" "nature" "architecture" "generative"))

;; Data maps
(define-map artwork-metadata uint {
    title: (string-ascii 64),
    artist: principal,
    description: (string-ascii 512),
    image-url: (string-ascii 256),
    category: (string-ascii 32),
    creation-date: uint,
    royalty-rate: uint,
    verified: bool
})

(define-map artwork-pricing uint {
    price: uint,
    for-sale: bool,
    currency: (string-ascii 10)
})

(define-map artist-profiles principal {
    name: (string-ascii 64),
    bio: (string-ascii 256),
    verified: bool,
    total-artworks: uint,
    registration-block: uint
})

(define-map approved-operators {owner: principal, operator: principal} bool)

(define-map category-stats (string-ascii 32) {
    count: uint,
    total-volume: uint
})

(define-map blacklisted-addresses principal bool)

;; Input validation functions
(define-private (validate-string-length (input (string-ascii 512)) (max-len uint))
    (and (> (len input) u0) (<= (len input) max-len)))

(define-private (validate-principal (addr principal))
    (and (not (is-eq addr 'ST000000000000000000002AMW42H))
         (is-none (map-get? blacklisted-addresses addr))))

(define-private (validate-category (category (string-ascii 32)))
    (is-some (index-of (var-get valid-categories) category)))

(define-private (validate-url (url (string-ascii 256)))
    (and (validate-string-length url max-url-length)
         (or (is-eq (unwrap-panic (slice? url u0 u8)) "https://")
             (is-eq (unwrap-panic (slice? url u0 u7)) "http://"))))

(define-private (validate-price (price uint))
    (and (> price u0) (< price u1000000000000))) ;; Max 1M STX

(define-private (validate-royalty-rate (rate uint))
    (<= rate max-royalty-rate))

;; Security functions
(define-private (is-contract-paused)
    (var-get paused))

(define-private (is-owner (token-id uint) (user principal))
    (is-eq user (unwrap! (nft-get-owner? secureart-marketplace token-id) false)))

(define-private (is-approved-operator (owner principal) (operator principal))
    (default-to false (map-get? approved-operators {owner: owner, operator: operator})))

(define-private (calculate-fee (amount uint) (rate uint))
    (/ (* amount rate) u10000))

;; Read-only functions
(define-read-only (get-last-token-id)
    (ok (var-get last-token-id)))

(define-read-only (get-token-uri (token-id uint))
    (ok (concat (var-get base-token-uri) (int-to-ascii token-id))))

(define-read-only (get-owner (token-id uint))
    (ok (nft-get-owner? secureart-marketplace token-id)))

(define-read-only (get-artwork-metadata (token-id uint))
    (map-get? artwork-metadata token-id))

(define-read-only (get-artwork-pricing (token-id uint))
    (map-get? artwork-pricing token-id))

(define-read-only (get-artist-profile (artist principal))
    (map-get? artist-profiles artist))

(define-read-only (get-collection-limit)
    (ok (var-get collection-limit)))

(define-read-only (get-total-volume)
    (ok (var-get total-volume)))

(define-read-only (get-category-stats (category (string-ascii 32)))
    (map-get? category-stats category))

(define-read-only (get-platform-fee-rate)
    (ok (var-get platform-fee-rate)))

(define-read-only (get-valid-categories)
    (ok (var-get valid-categories)))

(define-read-only (is-paused)
    (ok (var-get paused)))

;; Public functions with comprehensive validation

;; Create and mint new artwork NFT with full validation
(define-public (create-artwork 
    (validated-recipient principal) 
    (validated-title (string-ascii 64)) 
    (validated-description (string-ascii 512)) 
    (validated-image-url (string-ascii 256))
    (validated-category (string-ascii 32))
    (validated-royalty-rate uint)
    (validated-initial-price uint))
    (let 
        (
            (token-id (+ (var-get last-token-id) u1))
            (current-block-height block-height)
        )
        ;; Security checks
        (asserts! (not (is-contract-paused)) (err u399))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= token-id (var-get collection-limit)) err-mint-limit-exceeded)
        
        ;; Input validation
        (asserts! (validate-principal validated-recipient) err-zero-address)
        (asserts! (validate-string-length validated-title max-title-length) err-invalid-string)
        (asserts! (validate-string-length validated-description max-description-length) err-invalid-string)
        (asserts! (validate-url validated-image-url) err-invalid-input)
        (asserts! (validate-category validated-category) err-invalid-input)
        (asserts! (validate-royalty-rate validated-royalty-rate) err-invalid-royalty)
        (asserts! (validate-price validated-initial-price) err-invalid-price)
        
        ;; Mint the NFT with validated data
        (try! (nft-mint? secureart-marketplace token-id validated-recipient))
        
        ;; Set artwork metadata with validated inputs
        (map-set artwork-metadata token-id {
            title: validated-title,
            artist: validated-recipient,
            description: validated-description,
            image-url: validated-image-url,
            category: validated-category,
            creation-date: current-block-height,
            royalty-rate: validated-royalty-rate,
            verified: false
        })
        
        ;; Set initial pricing with validated price
        (map-set artwork-pricing token-id {
            price: validated-initial-price,
            for-sale: true,
            currency: "STX"
        })
        
        ;; Update artist profile safely
        (let ((current-profile (default-to 
                {name: "", bio: "", verified: false, total-artworks: u0, registration-block: current-block-height} 
                (map-get? artist-profiles validated-recipient))))
            (map-set artist-profiles validated-recipient 
                (merge current-profile {total-artworks: (+ (get total-artworks current-profile) u1)})))
        
        ;; Update category stats safely
        (let ((current-stats (default-to {count: u0, total-volume: u0} 
                (map-get? category-stats validated-category))))
            (map-set category-stats validated-category
                (merge current-stats {count: (+ (get count current-stats) u1)})))
        
        (var-set last-token-id token-id)
        (ok token-id)))

;; Secure purchase function with validation
(define-public (purchase-artwork (validated-token-id uint))
    (let 
        (
            (artwork-price-data (unwrap! (map-get? artwork-pricing validated-token-id) err-token-not-found))
            (artwork-meta (unwrap! (map-get? artwork-metadata validated-token-id) err-token-not-found))
            (current-owner (unwrap! (nft-get-owner? secureart-marketplace validated-token-id) err-token-not-found))
            (price (get price artwork-price-data))
            (artist (get artist artwork-meta))
            (royalty-rate (get royalty-rate artwork-meta))
            (category (get category artwork-meta))
            (platform-fee (calculate-fee price (var-get platform-fee-rate)))
            (royalty-fee (calculate-fee price royalty-rate))
            (seller-amount (- price (+ platform-fee royalty-fee)))
        )
        ;; Security and validation checks
        (asserts! (not (is-contract-paused)) (err u399))
        (asserts! (validate-principal tx-sender) err-zero-address)
        (asserts! (validate-principal current-owner) err-zero-address)
        (asserts! (get for-sale artwork-price-data) err-not-for-sale)
        (asserts! (>= (stx-get-balance tx-sender) price) err-insufficient-funds)
        (asserts! (not (is-eq tx-sender current-owner)) err-invalid-input)
        
        ;; Execute secure transfers
        (try! (stx-transfer? seller-amount tx-sender current-owner))
        
        ;; Transfer royalty to artist if different from seller
        (if (not (is-eq artist current-owner))
            (try! (stx-transfer? royalty-fee tx-sender artist))
            true)
        
        ;; Transfer platform fee to contract owner
        (try! (stx-transfer? platform-fee tx-sender contract-owner))
        
        ;; Transfer NFT securely
        (try! (nft-transfer? secureart-marketplace validated-token-id current-owner tx-sender))
        
        ;; Update artwork status
        (map-set artwork-pricing validated-token-id
            (merge artwork-price-data {for-sale: false}))
        
        ;; Update volume statistics
        (var-set total-volume (+ (var-get total-volume) price))
        (let ((current-stats (default-to {count: u0, total-volume: u0} 
                (map-get? category-stats category))))
            (map-set category-stats category
                (merge current-stats {total-volume: (+ (get total-volume current-stats) price)})))
        
        (ok validated-token-id)))

;; Secure listing function
(define-public (list-for-sale (validated-token-id uint) (validated-price uint))
    (let ((artwork-price-data (unwrap! (map-get? artwork-pricing validated-token-id) err-token-not-found)))
        (asserts! (not (is-contract-paused)) (err u399))
        (asserts! (is-owner validated-token-id tx-sender) err-not-token-owner)
        (asserts! (validate-price validated-price) err-invalid-price)
        (ok (map-set artwork-pricing validated-token-id
            (merge artwork-price-data {price: validated-price, for-sale: true})))))

;; Secure unlisting function
(define-public (unlist-from-sale (validated-token-id uint))
    (let ((artwork-price-data (unwrap! (map-get? artwork-pricing validated-token-id) err-token-not-found)))
        (asserts! (not (is-contract-paused)) (err u399))
        (asserts! (is-owner validated-token-id tx-sender) err-not-token-owner)
        (ok (map-set artwork-pricing validated-token-id
            (merge artwork-price-data {for-sale: false})))))

;; Secure transfer function
(define-public (transfer (validated-token-id uint) (validated-sender principal) (validated-recipient principal))
    (let ((artwork-price-data (unwrap! (map-get? artwork-pricing validated-token-id) err-token-not-found)))
        (asserts! (not (is-contract-paused)) (err u399))
        (asserts! (validate-principal validated-sender) err-zero-address)
        (asserts! (validate-principal validated-recipient) err-zero-address)
        (asserts! (or (is-owner validated-token-id tx-sender) 
                     (is-approved-operator validated-sender tx-sender))
                 err-not-token-owner)
        ;; Remove from sale when transferred
        (map-set artwork-pricing validated-token-id
            (merge artwork-price-data {for-sale: false}))
        (nft-transfer? secureart-marketplace validated-token-id validated-sender validated-recipient)))

;; Secure approval function
(define-public (set-approval-for-all (validated-operator principal) (approved bool))
    (begin
        (asserts! (not (is-contract-paused)) (err u399))
        (asserts! (validate-principal validated-operator) err-zero-address)
        (asserts! (not (is-eq tx-sender validated-operator)) err-invalid-input)
        (ok (map-set approved-operators {owner: tx-sender, operator: validated-operator} approved))))

;; Secure profile update
(define-public (update-artist-profile (validated-name (string-ascii 64)) (validated-bio (string-ascii 256)))
    (let ((current-profile (default-to 
            {name: "", bio: "", verified: false, total-artworks: u0, registration-block: block-height} 
            (map-get? artist-profiles tx-sender))))
        (asserts! (not (is-contract-paused)) (err u399))
        (asserts! (validate-string-length validated-name max-name-length) err-invalid-string)
        (asserts! (validate-string-length validated-bio max-bio-length) err-invalid-string)
        (ok (map-set artist-profiles tx-sender
            (merge current-profile {name: validated-name, bio: validated-bio})))))

;; Admin functions with validation

;; Secure artist verification
(define-public (verify-artist (validated-artist principal))
    (let ((artist-profile (default-to 
            {name: "", bio: "", verified: false, total-artworks: u0, registration-block: block-height} 
            (map-get? artist-profiles validated-artist))))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (validate-principal validated-artist) err-zero-address)
        (ok (map-set artist-profiles validated-artist
            (merge artist-profile {verified: true})))))

;; Secure URI update
(define-public (set-base-token-uri (validated-new-base-uri (string-ascii 256)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (not (var-get metadata-frozen)) err-metadata-frozen)
        (asserts! (validate-url validated-new-base-uri) err-invalid-input)
        (ok (var-set base-token-uri validated-new-base-uri))))

;; Secure limit update
(define-public (set-collection-limit (validated-new-limit uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (and (> validated-new-limit u0) (< validated-new-limit u100000)) err-invalid-input)
        (ok (var-set collection-limit validated-new-limit))))

;; Secure fee update
(define-public (set-platform-fee-rate (validated-new-rate uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= validated-new-rate max-platform-fee) err-invalid-royalty)
        (ok (var-set platform-fee-rate validated-new-rate))))

;; Emergency controls
(define-public (pause-contract)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set paused true))))

(define-public (unpause-contract)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set paused false))))

(define-public (blacklist-address (address principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (not (is-eq address contract-owner)) err-invalid-input)
        (ok (map-set blacklisted-addresses address true))))

(define-public (freeze-metadata)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set metadata-frozen true))))

;; Initialize contract
(begin
    (print "SecureArt Marketplace NFT contract deployed successfully")
    (print {
        contract-owner: contract-owner, 
        collection-limit: (var-get collection-limit),
        platform-fee: (var-get platform-fee-rate),
        security-features: "input-validation-blacklist-pause"
    }))