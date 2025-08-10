# ZK-Marketplace: Auction-Based Zero-Knowledge Proof Verification Platform

A decentralized marketplace built on Stacks blockchain where clients post zero-knowledge proof verification jobs and validators compete through competitive bidding to provide verification services.

## 🎯 Overview

ZK-Marketplace creates a trustless, auction-based ecosystem for zero-knowledge proof verification by:
- Enabling clients to post verification jobs with budgets and requirements
- Allowing qualified validators to bid competitively on verification tasks
- Supporting multiple ZK proof protocols (STARK, SNARK, Bulletproof, Sonic)
- Providing automated escrow and payment settlement
- Tracking validator performance and reputation metrics

## 🏗️ Architecture

### Core Components

1. **Job Marketplace**: Clients post verification jobs with budgets and deadlines
2. **Validator Network**: Registered verifiers with expertise profiles and ratings
3. **Bidding System**: Competitive auction mechanism for job assignment
4. **Protocol Registry**: Supported ZK proof types with configuration parameters
5. **Reputation System**: Performance tracking and rating system for validators

### Supported Protocols

- **STARK**: 0.6 STX minimum fee, complexity rating 8/10, ~120 blocks completion time
- **SNARK**: 0.5 STX minimum fee, complexity rating 6/10, ~100 blocks completion time  
- **Bulletproof**: 0.4 STX minimum fee, complexity rating 4/10, ~80 blocks completion time
- **Sonic**: 0.55 STX minimum fee, complexity rating 7/10, ~110 blocks completion time

## 🚀 Getting Started

### Prerequisites

- Stacks wallet with STX tokens
- Understanding of zero-knowledge proof verification
- For validators: expertise in cryptographic proof systems

### System Initialization

The marketplace owner must initialize the platform:

```clarity
;; Initialize marketplace with supported protocols
(contract-call? .zk-marketplace initialize-marketplace)
```

## 👥 User Roles

### 1. Marketplace Owner
- Platform administrator and operator
- Can add new ZK protocols
- Can enable/disable the marketplace
- Can withdraw platform earnings
- Sets global parameters like minimum bid amounts

### 2. Clients (Proof Requesters)
- Post verification jobs with budgets
- Review and accept validator bids
- Pay for successful verifications
- Can withdraw funds from expired jobs

### 3. Validators (Proof Verifiers)
- Register with business profiles and expertise areas
- Bid on verification jobs
- Perform proof verification work
- Build reputation through successful completions

## 📋 Core Workflows

### Becoming a Validator

```clarity
;; Register as a marketplace validator
(contract-call? .zk-marketplace join-as-validator 
  "CryptoProof Labs"  ;; business name
  (list "stark" "snark" "bulletproof"))  ;; expertise areas
```

### Posting a Verification Job

```clarity
;; Post a new verification job
(contract-call? .zk-marketplace post-verification-job
  "stark"  ;; protocol type
  0x1234...abcd  ;; proof data hash
  0xabcd...1234  ;; input parameters
  0x9876...cdef  ;; verification key
  u2000000  ;; max budget (2 STX)
  u200)  ;; bidding window (200 blocks)
```

### Submitting a Bid

```clarity
;; Submit competitive bid for a job
(contract-call? .zk-marketplace submit-bid
  u1  ;; job ID
  u1500000  ;; bid amount (1.5 STX)
  u150)  ;; estimated completion time (blocks)
```

### Accepting a Bid

```clarity
;; Client accepts a validator's bid
(contract-call? .zk-marketplace accept-bid
  u1  ;; job ID  
  'SPVALIDATOR...ADDRESS)  ;; chosen validator
```

### Completing Verification

```clarity
;; Validator submits verification results
(contract-call? .zk-marketplace complete-verification
  u1  ;; job ID
  true)  ;; verification successful
```

## 🔍 Query Functions

### Job Information

```clarity
;; Get job details and status
(contract-call? .zk-marketplace get-job-details u1)

;; Check if job verification was successful
(contract-call? .zk-marketplace is-job-verified u1)
```

### Validator Profiles

```clarity
;; Get validator business profile
(contract-call? .zk-marketplace get-validator-profile 'SPVALIDATOR...ADDRESS)
```

### Bid Tracking

```clarity
;; Get specific bid information
(contract-call? .zk-marketplace get-bid-info u1 'SPVALIDATOR...ADDRESS)
```

### Client Activity

```clarity
;; Get client statistics
(contract-call? .zk-marketplace get-client-stats 'SPCLIENT...ADDRESS)
```

### Protocol Details

```clarity
;; Get protocol configuration
(contract-call? .zk-marketplace get-protocol-details "stark")

;; Get current minimum bid
(contract-call? .zk-marketplace get-minimum-bid-amount)
```

## 💰 Economic Model

### Fee Structure
- **Minimum Bid**: 0.5 STX (configurable by owner)
- **Protocol-Specific Minimums**: 0.4 - 0.6 STX based on complexity
- **Escrow System**: Client funds locked until job completion
- **Automatic Refunds**: Unused budget returned to clients

### Payment Flow
1. Client locks maximum budget when posting job
2. Validators submit competitive bids
3. Client accepts winning bid
4. Upon completion, validator receives bid amount
5. Remaining budget refunded to client

## 🔒 Security Features

### Escrow Protection
- Client funds locked in smart contract
- Automatic payment release on completion
- Refund mechanism for expired jobs

### Reputation System
- Success rate tracking for validators
- Performance-based rating adjustments
- Historical job completion metrics

### Quality Assurance
- Protocol-specific complexity ratings
- Minimum bid requirements prevent spam
- Time-bounded bidding windows

## 📊 Job Structure

Each verification job contains:
- **Client**: Job poster address
- **Protocol Type**: ZK proof scheme (STARK, SNARK, etc.)
- **Proof Data**: Hash of the proof to verify
- **Input Parameters**: Public inputs for verification
- **Verification Key**: Cryptographic key for proof validation
- **Max Budget**: Maximum payment amount
- **Winning Bid**: Accepted bid amount
- **Assigned Validator**: Selected verifier address
- **Completion Status**: Job and verification status
- **Timestamps**: Posting time and bid deadline

## 📈 Validator Profile

Each validator maintains:
- **Business Name**: Public identifier
- **Expertise Areas**: Supported protocols list
- **Success Rate**: Percentage of successful verifications
- **Jobs Completed**: Total verification count
- **Average Rating**: Performance score
- **Availability Status**: Currently accepting jobs

## 🛡️ Error Codes

- `u300`: Forbidden access/unauthorized operation
- `u301`: Job not found
- `u302`: Invalid job parameters or state
- `u303`: Job already exists/completed
- `u304`: Bid amount too low
- `u305`: Validator not found/registered
- `u306`: Unsupported protocol type

## 🔧 Administrative Functions

### Protocol Management
```clarity
;; Add new ZK protocol support
(contract-call? .zk-marketplace add-protocol
  "plonk"  ;; protocol name
  u700000  ;; minimum fee (0.7 STX)
  u9  ;; complexity rating
  u140)  ;; average completion time
```

### Platform Control
```clarity
;; Update minimum bid requirements
(contract-call? .zk-marketplace update-minimum-bid u600000)

;; Temporarily disable marketplace
(contract-call? .zk-marketplace disable-marketplace)

;; Re-enable marketplace operations
(contract-call? .zk-marketplace enable-marketplace)
```

## 🌐 Use Cases

### 1. **DeFi Protocol Audits**
- Smart contracts post proofs for third-party verification
- Auditors bid competitively on review jobs
- Automated payment upon completion

### 2. **Research Verification**
- Academic institutions verify complex proofs
- Peer review through marketplace bidding
- Reputation-based validator selection

### 3. **Compliance Verification**
- Regulatory proofs verified by certified validators
- Competition ensures cost-effectiveness
- Audit trails for compliance reporting

### 4. **Cross-Chain Verification**
- Bridge protocols verify proofs from other chains
- Specialized validators for different ecosystems
- Economic incentives for accurate verification

### 5. **Privacy Applications**
- Anonymous credential verification
- Private computation result validation
- Zero-knowledge identity proof checking

## 💡 Advanced Features

### Batch Operations
- Validators can bid on multiple jobs efficiently
- Bulk job posting for related verifications
- Optimized gas costs for frequent users

### Reputation Weighting
- Higher-rated validators can command premium pricing
- Success rate affects future bid competitiveness
- Long-term relationship building between clients and validators

### Emergency Functions
- Job withdrawal for expired listings
- Fund recovery mechanisms
- Platform shutdown capabilities

## 🤝 Integration Examples

### Client Integration
```javascript
// Post verification job from web app
const jobResult = await callReadOnlyFunction({
  contractAddress: 'SP...',
  contractName: 'zk-marketplace',
  functionName: 'post-verification-job',
  functionArgs: [
    stringAsciiCV('stark'),
    bufferCV('0x...'),
    bufferCV('0x...'),
    bufferCV('0x...'),
    uintCV(2000000),
    uintCV(200)
  ]
});
```

### Validator Integration
```javascript
// Monitor new jobs and submit bids
const jobDetails = await callReadOnlyFunction({
  contractAddress: 'SP...',
  contractName: 'zk-marketplace', 
  functionName: 'get-job-details',
  functionArgs: [uintCV(jobId)]
});

// Submit competitive bid
await makeContractCall({
  contractAddress: 'SP...',
  contractName: 'zk-marketplace',
  functionName: 'submit-bid',
  functionArgs: [
    uintCV(jobId),
    uintCV(bidAmount),
    uintCV(estimatedTime)
  ]
});
```

## 🔮 Future Enhancements

- **Multi-round bidding** with bid increments
- **Validator staking** for additional security
- **Cross-protocol verification** job bundling
- **Oracle integration** for external data verification
- **Mobile validator apps** for on-the-go bidding
- **Automated job matching** based on expertise
- **Insurance mechanisms** for high-value verifications

## ⚠️ Important Considerations

- **Validator Expertise**: Ensure validators have genuine cryptographic knowledge
- **Job Complexity**: Match job difficulty with validator capabilities  
- **Economic Incentives**: Balance competitive pricing with quality assurance
- **Gas Costs**: Consider transaction fees in bid calculations
- **Time Constraints**: Allow adequate time for thorough verification

## 📜 License

This project is open source. Review license terms before commercial use.

---

**Note**: This marketplace requires careful economic modeling and should be thoroughly tested and audited before mainnet deployment. The competitive bidding mechanism creates strong incentives for accurate verification while maintaining cost efficiency.