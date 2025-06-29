# Weave 🎨

A secure, feature-rich NFT marketplace built on the Stacks blockchain, designed specifically for digital artists and collectors. Weave provides a comprehensive ecosystem for creating, trading, and managing digital art NFTs with enterprise-grade security and validation.

## ✨ Features

### 🖼️ **Digital Art Focus**
- Specialized metadata structure for artwork (title, artist, description, category)
- Pre-defined art categories (digital-art, photography, abstract, etc.)
- Artist profile system with verification badges
- Creation date tracking and provenance

### 💰 **Built-in Marketplace**
- Direct STX payments with automatic fee distribution
- Configurable royalty system for artists (up to 10%)
- Platform fee structure (default 2%)
- List/unlist functionality for artwork owners
- Volume tracking across categories

### 🔒 **Enterprise Security**
- Comprehensive input validation for all parameters
- Address blacklisting system
- Contract pause/unpause mechanism
- Zero address protection
- URL validation for metadata
- Rate limiting on fees and royalties

### 👤 **Artist Management**
- Artist profile creation and updates
- Verification system for legitimate artists
- Portfolio tracking (total artworks created)
- Registration block tracking

### 📊 **Analytics & Insights**
- Total marketplace volume tracking
- Category-specific statistics
- Artist performance metrics
- Trading history preservation

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) for local development
- [Stacks CLI](https://docs.stacks.co/build-apps/references/stacks-cli) for deployment
- Node.js 16+ for frontend integration

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/your-username/weave.git
cd weave
```

2. **Initialize Clarinet project**
```bash
clarinet new weave-marketplace
cd weave-marketplace
```

3. **Add the contract**
```bash
# Copy the contract file to contracts/
cp ../secureart-marketplace.clar contracts/
```

4. **Configure Clarinet.toml**
```toml
[contracts.secureart-marketplace]
path = "contracts/secureart-marketplace.clar"
```

### Deployment

#### Local Deployment
```bash
clarinet console
```

#### Testnet Deployment
```bash
clarinet deploy --testnet
```

#### Mainnet Deployment
```bash
clarinet deploy --mainnet
```

## 📋 Contract Functions

### **Public Functions**

#### Minting & Creation
- `create-artwork()` - Mint new artwork NFT with full validation
- `update-artist-profile()` - Update artist name and bio

#### Marketplace Operations
- `purchase-artwork()` - Buy listed artwork with automatic fee distribution
- `list-for-sale()` - List artwork for sale at specified price
- `unlist-from-sale()` - Remove artwork from marketplace

#### NFT Operations
- `transfer()` - Secure NFT transfer with validation
- `set-approval-for-all()` - Set operator approval

#### Admin Functions
- `verify-artist()` - Verify legitimate artists
- `set-platform-fee-rate()` - Update platform fees
- `pause-contract()` / `unpause-contract()` - Emergency controls
- `blacklist-address()` - Security management

### **Read-Only Functions**
- `get-artwork-metadata()` - Retrieve artwork details
- `get-artwork-pricing()` - Get current pricing info
- `get-artist-profile()` - Artist information
- `get-category-stats()` - Category analytics
- `get-total-volume()` - Marketplace volume

## 🛡️ Security Features

### Input Validation
- **String Length Validation**: Ensures all text inputs are within bounds
- **Principal Validation**: Prevents zero addresses and checks blacklist
- **URL Validation**: Validates metadata URLs for security
- **Price Validation**: Prevents invalid pricing attacks
- **Category Validation**: Only allows whitelisted categories

### Access Control
- **Owner-only Functions**: Critical functions restricted to contract owner
- **Token Owner Checks**: Transfer permissions properly validated
- **Operator Approval**: Secure delegation system

### Emergency Controls
- **Contract Pause**: Halt all operations during emergencies
- **Address Blacklisting**: Block malicious actors
- **Metadata Freezing**: Permanent metadata protection

## 📊 Usage Examples

### Creating Artwork
```clarity
(contract-call? .secureart-marketplace create-artwork
  'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE
  "Digital Sunset"
  "A beautiful digital representation of a sunset over the ocean"
  "https://cdn.weave.art/images/sunset-001.png"
  "digital-art"
  u500  ;; 5% royalty
  u1000000)  ;; 1 STX price
```

### Purchasing Artwork
```clarity
(contract-call? .secureart-marketplace purchase-artwork u1)
```

### Listing for Sale
```clarity
(contract-call? .secureart-marketplace list-for-sale u1 u2000000)  ;; 2 STX
```

## 🏗️ Architecture

### Contract Structure
```
secureart-marketplace.clar
├── Constants & Error Codes
├── Data Variables & Maps
├── Input Validation Functions
├── Security Functions
├── Read-Only Functions
├── Public Functions
└── Admin Functions
```

### Data Maps
- `artwork-metadata` - Core artwork information
- `artwork-pricing` - Marketplace pricing data
- `artist-profiles` - Artist information and stats
- `approved-operators` - NFT delegation system
- `category-stats` - Analytics data
- `blacklisted-addresses` - Security management

## 🧪 Testing

### Unit Tests
```bash
clarinet test
```

### Integration Tests
```bash
clarinet console
```

Example test scenarios:
- Artwork creation and validation
- Marketplace transactions
- Security controls
- Error handling
- Edge cases

## 🔧 Configuration

### Environment Variables
- `COLLECTION_LIMIT` - Maximum NFTs (default: 3000)
- `PLATFORM_FEE` - Platform fee in basis points (default: 200)
- `BASE_URI` - Metadata base URL

### Categories
The contract supports these predefined categories:
- digital-art, photography, abstract, portrait, landscape
- animation, 3d-art, pixel-art, vector-art, mixed-media
- conceptual, surreal, minimalist, pop-art, street-art
- fantasy, sci-fi, nature, architecture, generative

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Clarity best practices
- Add comprehensive tests for new features
- Update documentation for API changes
- Ensure security validations are in place


## 🏆 Acknowledgments

- Stacks Foundation for blockchain infrastructure
- Clarity language developers
- Open source NFT community
- Digital artists who inspire innovation
