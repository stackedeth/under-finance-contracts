# Under Finance

> The first undercollateralized borrowing and lending protocol for Bitcoin on Starknet

## 🎯 Problem Statement

Bitcoin DeFi currently lacks credit markets. Today's landscape forces users to overcollateralize loans, which:

- Locks up significant capital inefficiently
- Excludes millions who lack sufficient collateral
- Restricts liquidity and prevents Bitcoin from functioning as productive capital
- Limits the growth potential of Bitcoin-based decentralized finance

## 💡 Solution

Under Finance introduces a revolutionary approach to Bitcoin lending by creating the **first undercollateralized borrowing and lending protocol** on Starknet. Our protocol enables both borrowers and lenders to opt into KYC-enabled credit profiles, unlocking a new paradigm in DeFi lending.

### Core Value Propositions

**For Borrowers:**

- Unlock liquidity from BTC holdings without selling
- Access credit based on verified identity and creditworthiness
- Reduced collateral requirements through trust-based lending
- Flexible borrowing caps based on credit assessment

**For Lenders:**

- Optional KYC for access to higher-trust, higher-yield markets
- Flexible risk exposure management
- Choice between KYC-gated or permissionless lending pools
- Transparent yield distribution with interest accrual

## 🏗️ Protocol Architecture

### Market Spectrum

Under Finance creates a flexible lending spectrum that accommodates different risk profiles:

1. **Fully KYC'ed Undercollateralized Loans**

   - KYC borrower ↔ KYC lender
   - Trust-enabled credit with minimal collateral
   - Higher borrowing caps for verified participants

2. **Hybrid Risk-Priced Pools**

   - KYC borrower ↔ Non-KYC lender
   - Risk-adjusted interest rates
   - Moderate collateral requirements

3. **Traditional Overcollateralized Lending**
   - Non-KYC borrower ↔ Lender
   - Standard DeFi lending mechanics
   - Full collateralization requirements

### Key Components

#### 1. Identity Layer

Borrowers and lenders verify identity and creditworthiness through integrations like **Reclaim Protocol**:

- Decentralized identity verification
- Credit score assessment
- On-chain proof of creditworthiness
- Privacy-preserving credential management

#### 2. Market Matching Engine

Smart contracts intelligently route participants into appropriate pools based on:

- KYC status of both parties
- Credit assessment scores
- Desired risk/reward profiles
- Available liquidity

#### 3. Risk Engine

Transparent and algorithmic risk management:

- Dynamic credit scoring
- Automated collateral requirement calculation
- Real-time interest rate adjustments
- Threshold-based liquidation mechanics

#### 4. Settlement Layer

All operations execute trustlessly on Starknet:

- Loan origination and disbursement
- Automated repayment processing
- Collateral management
- Liquidation execution

## 🔄 Data Flow Architecture

### Borrowing Flow

```
User Request → Identity Verification → Credit Assessment →
Admin Review → Pool Routing → Collateral Lock →
Loan Origination → Asset Disbursement
```

**Step-by-step:**

1. **Registration**: Borrower submits request with entity details, asset preferences, collateral, and desired cap
2. **Verification**: Off-chain identity verification and credit assessment
3. **Onboarding**: Admin approves and completes borrower onboarding with KYC flag
4. **Activation**: Borrower profile becomes active with verified status
5. **Borrowing**: Borrower can claim assets up to their approved cap
6. **Repayment**: Borrower repays borrowed amount plus interest
7. **Collateral Return**: Upon full repayment, borrower reclaims collateral

### Lending Flow

```
User → Optional KYC → Pool Selection → Liquidity Deposit →
Receipt Token Minting → Interest Accrual → Yield Distribution
```

**Step-by-step:**

1. **Pool Selection**: Lender chooses target borrower pool (identified by key)
2. **Deposit**: Lender deposits assets into selected pool
3. **Receipt Tokens**: Lender receives UFBTC tokens representing pool share
4. **Interest Accrual**: Automatic yield accumulation from borrower repayments
5. **Withdrawal**: Lender redeems UFBTC tokens for principal plus earned interest

### Liquidation Flow

```
Health Monitor → Threshold Breach Detection → Liquidation Trigger →
Collateral Auction → Debt Recovery → Lender Protection
```

**Risk Management:**

- Continuous health factor monitoring
- Automated liquidation triggers
- Fair collateral distribution
- Lender capital protection

## 📁 Technical Implementation

### Smart Contract Architecture

The protocol is implemented in Cairo for Starknet with three core contracts:

#### Market Contract (`market.cairo`)

The main protocol contract that handles all core functionality:

**Storage Structure:**

- `key_cnt`: Incremental counter for borrower identification
- `admin`: Platform administrator address
- `owner`: Contract owner address
- `key_to_borrower_queue`: Mapping of pending borrower registrations
- `key_to_borrower_details`: Mapping of verified borrower profiles
- `total_deposit`: Aggregate liquidity across all pools
- `erc20`: Component for UFBTC receipt tokens

**Key Functions:**

**Admin Interface (`IAdmin`):**

```cairo
fn register_borrower(details: BorrowerReqDetails) -> u8
fn complete_borrower_onboarding(key: u8)
fn add_admin(admin: ContractAddress)
```

**Lender Interface (`ILender`):**

```cairo
fn deposit(key: u8, amount: u256)
fn withdraw(key: u8)
```

**Borrower Interface (`IBorrower`):**

```cairo
fn repay(key: u8, amount: u256)
fn claim_collateral(key: u8)
fn claim_assets(key: u8, receiver: ContractAddress, amount: u256)
fn get_borrower_details(key: u8) -> BorrowerDetails
```

#### Data Structures (`interface.cairo`)

**BorrowerReqDetails** - Initial registration request:

```cairo
struct BorrowerReqDetails {
    borrower_entity: felt252,      // Entity identifier
    asset: ContractAddress,         // Asset to borrow (e.g., WBTC)
    collateral: ContractAddress,    // Collateral token address
    borrower: ContractAddress,      // Borrower wallet address
    cap: u256,                      // Maximum borrowing limit
}
```

**BorrowerDetails** - Verified borrower profile:

```cairo
struct BorrowerDetails {
    borrower_entity: felt252,
    kyc: bool,                          // KYC verification status
    asset: ContractAddress,
    collateral: ContractAddress,
    borrower: ContractAddress,
    cap: u256,
    verified_by_platform: bool,         // Admin approval flag
    started_from: u64,                  // Activation timestamp
}
```

#### Events (`events.cairo`)

```cairo
struct BorrowerReqEvent {
    id: u8,  // Emitted when new borrower registers
}
```

### Receipt Token System

The protocol uses an ERC20 token system (UFBTC) for representing lender deposits:

- **Minting**: When lenders deposit assets, they receive UFBTC tokens proportional to their deposit
- **Interest Accrual**: The value of UFBTC tokens increases as borrowers repay loans with interest
- **Redemption**: Lenders burn UFBTC tokens to withdraw principal plus accumulated yield

**Reward Calculation:**

```cairo
reward_multiplier = (total_repaid - total_deposited) / total_deposited
withdrawal_amount = balance * reward_multiplier
```

### Security Features

1. **Access Control**:

   - Owner-only admin management
   - Admin-only borrower verification
   - Borrower-only asset claims

2. **Validation Guards**:

   - Zero-amount checks
   - Zero-address validation
   - Borrower authorization verification
   - Cap enforcement

3. **State Management**:
   - Two-stage borrower onboarding (request → approval)
   - Separate queue and active borrower mappings
   - Immutable borrower caps

## 🚀 Getting Started

### Prerequisites

- [Scarb](https://docs.swmansion.com/scarb/) - Cairo package manager
- [Starknet Foundry](https://foundry-rs.github.io/starknet-foundry/) - Smart contract development toolkit

### Installation

```bash
# Clone the repository
git clone https://github.com/stackedeth/under-finance-contracts
cd under-finance-contracts

# Install dependencies
scarb build
```

### Running Tests

```bash
snforge test
```

### Deployment

```bash
# Deploy to Starknet testnet
snforge deploy --network testnet

# Deploy to mainnet
snforge deploy --network mainnet
```

## 📊 Contract Interactions

### For Platform Admins

**1. Deploy Contract:**

```cairo
constructor(owner: ContractAddress, admin: ContractAddress)
```

**2. Approve Borrower:**

```cairo
complete_borrower_onboarding(key: 0)
```

### For Borrowers

**1. Register for Borrowing:**

```cairo
register_borrower({
    borrower_entity: 'COMPANY_NAME',
    asset: WBTC_ADDRESS,
    collateral: COLLATERAL_ADDRESS,
    borrower: YOUR_ADDRESS,
    cap: 100000000000000000000  // 100 tokens with 18 decimals
})
```

**2. Claim Borrowed Assets:**

```cairo
claim_assets(key: 0, receiver: RECEIVER_ADDRESS, amount: 50000000000000000000)
```

**3. Repay Loan:**

```cairo
repay(key: 0, amount: 50000000000000000000)
```

**4. Reclaim Collateral:**

```cairo
claim_collateral(key: 0)
```

### For Lenders

**1. Deposit Liquidity:**

```cairo
deposit(key: 0, amount: 10000000000000000000)  // 10 tokens
```

**2. Withdraw with Interest:**

```cairo
withdraw(key: 0)  // Returns principal + accrued interest
```

**Disclaimer**: Under Finance is experimental software. Use at your own risk. This protocol involves financial risk and participants should conduct their own due diligence before depositing or borrowing funds.
