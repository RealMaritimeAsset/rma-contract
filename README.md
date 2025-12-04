# Real Maritime Assets (RMA)

Tokenizing real-world ships into on-chain investment opportunities.  
RMA connects **stablecoins, ship RWAs, and governance** to open ship finance to private investors.

> Ships as Real World Assets (RWA), funded by private investors, settled in our own stablecoin.

---

## 1. Inspiration

The maritime industry has been a major global sector for over 100 years, and it continues to grow.  
It includes shipbuilding, shipping, port operations, and more — but we focused on **shipbuilding and ship finance**.

Today, when a company wants to build a ship:

- It relies on **banks, governments, and large institutions**.
- **Private investors** have almost no way to participate.
- There are **no real policies or platforms** that support small-ticket funding.

We wanted to solve this.

> Our goal:  
> **Tokenize expensive ships as RWAs**, break them into smaller units so that anyone can invest with small amounts,  
> and build a transparent, decentralized ecosystem around them.

On top of that:

- Investors can receive **dividends from ship profits**.
- Dual Layer Tokens (**DLT**) allow **multiple benefit layers** (securities, memberships, free boarding tickets, etc.).
- All RWA transactions are settled in our **own stablecoin**, which is linked to a **governance token**.

---

## 2. What RMA Does

RMA is a platform that intermediates between **private investors** and **shipping companies**,  
connecting them through three core on-chain processes:

1. **Stablecoin**
2. **RWA (tokenized ships on Dual Layer Token)**
3. **Governance**

### 2.1 Stablecoin

RMA uses a **crypto-collateralized stablecoin**:

- Users **deposit Ether as collateral** and **mint stablecoins**.
- For every **100 stablecoins issued**, the user receives **1 governance token**.
- **Chainlink Data Feeds** are used to:
  - Fetch collateral prices
  - Calculate liquidation prices
- **Chainlink Automation** runs at regular intervals:
  - Checks whether a user’s position should be liquidated.
  - If the collateral price drops below the threshold:
    - The user’s collateral is sold.
    - The user receives the remaining value **minus** the issued stablecoins and fees.

### 2.2 RWA (Tokenized Ships)

Each shipping company deploys **one RWA contract** per ship:

- When raising funds to build a new ship, the contract **mints RWA tokens**.
- These RWA tokens are implemented on **Dual Layer Token (DLT)**:
  - One parent ship RWA can mint **multiple child tokens**:
    - **Securities**: share in future profits (dividends)
    - **Memberships**: access rights, loyalty benefits
    - **Free boarding tickets**: usable as NFT tickets
- Ship metadata can be updated via **Chainlink Functions**:
  - For example: updating with **weather data** or other external APIs.

### 2.3 Governance

Governance tokens are obtained through **stablecoin issuance**:

- If a user holds a **certain amount** of governance tokens, they can:
  - **Create proposals**
  - **Vote** on key protocol parameters
- Governance can change:
  - Stablecoin **fees**
  - **Liquidation ratios**
  - Other risk parameters of the system

This closes the loop:

> Stablecoin ↔ Governance Token ↔ Governance Contract ↔ RWA Funding

---

## 3. How We Built It

- **Smart Contracts**

  - Solidity
  - **Foundry** toolkit
  - Remix (rapid prototyping and demos)

- **Chainlink Products**

  - **Data Feeds** (price oracles)
  - **Automation** (liquidation checks)
  - **Functions** (off-chain / API data → on-chain metadata updates)

- **Chain**

  - Ethereum **Sepolia Testnet**

- **Frontend**

  - **Next.js**
  - Tailwind CSS
  - ethers.js

- **Backend**
  - Node.js
  - MySQL

---

## 4. Challenges We Ran Into

### 4.1 Understanding the Maritime Industry

The maritime industry was completely new to us:

- We knew almost nothing about **shipbuilding or ship finance**.
- We had to invest a lot of time in **domain research**, not just coding.
- As technologists, this was a very different kind of “study” — but it was necessary to build a realistic product.

In the end, it helped us design a **more grounded and meaningful** use case.

### 4.2 Stablecoin Design

Designing the stablecoin was like studying **economics + math + DeFi** at the same time:

- We researched different types of stablecoins:
  - Overcollateralized, algorithmic, etc.
- We studied key concepts such as:
  - **Liquidation ratio**
  - **Debt repayment**
  - **Collateral value**
- Then we had to **translate these concepts into code**:
  - Mathematical formulas
  - State transitions
  - Liquidation flows

It took a lot of time and calculation, but it made our stablecoin **truly our own**, not a copy.

### 4.3 RWA Implementation (ERC-6960)

We wanted our RWA design to be **more than just ERC-20 or ERC-721**:

- A simple token didn’t feel exciting or flexible enough.
- During our research, we found **ERC-6960**, which supports a **dual-layer structure**.
- This allowed us to:
  - Tokenize a ship once.
  - Issue multiple token types (securities, memberships, tickets) **under the same parent RWA**.

This multi-layer structure felt like a perfect fit for complex real-world assets like ships.

---

## 5. Accomplishments We’re Proud Of

We have created a **small but powerful RMA ecosystem**:

- We connected:
  - **Stablecoin**,
  - **Governance token**,
  - **Governance mechanism**,
  - **RWA contracts**  
    into **one coherent platform**.
- Our **stablecoin implementation** is:
  - Entirely our own design
  - Not cloned from any existing stablecoin
- For the RWA contracts:
  - We didn’t just use ERC-6960 “as is”.
  - We **extended it** with features we needed for the maritime use case.
  - We plan to **contribute our improvements back to the EIP**.

We are especially proud of the **`RMAStablecoin.sol`** contract —  
it was written with extreme care and attention to detail.

---

## 6. What We Learned

### 6.1 Chainlink

Before writing code, we spent time studying:

- Chainlink **whitepapers**
- The architecture of the **Decentralized Oracle Network (DON)**
- How its products (Data Feeds, Automation, Functions) fit together

We also noticed how much Chainlink evolved compared to a year ago  
—for example, Automation became easier to use (no more registering specific functions manually).

### 6.2 Frontend

This hackathon was also our chance to learn **Next.js**:

- We built the frontend under **time pressure**, in a somewhat “messy” way.
- But this is part of the learning process:
  - Integrating contracts with React/Next.js
  - Handling wallet connections
  - Rendering complex RWA & stablecoin states

We also deepened our understanding of **blockchain UX**.

### 6.3 Smart Contracts

Our main personal goal was to **get much better at Solidity**:

- We became more comfortable with:
  - Interfaces
  - Contract modularization
  - Even some **inline assembly**
- Contracts are no longer intimidating to us.
- We feel like we made a **significant leap** in our Web3 engineering skills.

---

## 7. What’s Next for Real Maritime Assets (RMA)

1. **Deploy to Mainnet (or Production-Ready Network)**

   - We want to refine and deploy RMA so users can **actually invest in tokenized ships**.

2. **Contract Refactoring**

   - We plan to clean up and optimize parts of the codebase  
     (except for `RMAStablecoin.sol`, which is already highly polished).

3. **CCIP Integration**

   - We learned how to move ERC-20 and ERC-721 across chains,  
     but we couldn’t complete it for DLT in this hackathon.
   - Cross-chain RWA support via **Chainlink CCIP** remains a major milestone.

4. **Frontend Improvements**

   - Compared to the contracts, our frontend is still behind:
     - More pages and flows are needed.
     - We ended up demoing some flows with Remix, which was a bit disappointing.
   - We’re committed to:
     - Completing all planned pages
     - Connecting them fully to the contracts
     - Providing a smoother UX for investors and shipping companies.

---

## 8. Built With

- **Smart Contracts**

  - Solidity
  - Foundry
  - Remix

- **Chainlink**

  - Data Feeds
  - Automation
  - Functions

- **Blockchain**

  - Ethereum Sepolia Testnet

- **Frontend**

  - Next.js
  - Tailwind CSS
  - ethers.js

- **Backend**
  - Node.js
  - MySQL
