// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LoanLink is ReentrancyGuard {
    struct Loan {
        address borrower;
        uint256 amount;
        uint256 interestRate;
        uint256 duration;
        uint256 startTime;
        address lender;
        bool isActive;
        bool isRepaid;
    }

    struct CreditScore {
        uint256 score;
        uint256 lastUpdated;
        uint256 totalLoans;
        uint256 repaidLoans;
    }

    mapping(address => CreditScore) public creditScores;
    mapping(uint256 => Loan) public loans;
    uint256 public loanCount;
    IERC20 public lendingToken;

    constructor(address _tokenAddress) {
        lendingToken = IERC20(_tokenAddress);
    }

    function createLoanRequest(
        uint256 amount,
        uint256 interestRate,
        uint256 duration
    ) external {
        require(creditScores[msg.sender].score > 300, "Insufficient credit score");
        
        loans[loanCount] = Loan({
            borrower: msg.sender,
            amount: amount,
            interestRate: interestRate,
            duration: duration,
            startTime: 0,
            lender: address(0),
            isActive: false,
            isRepaid: false
        });
        loanCount++;
    }

    function fundLoan(uint256 loanId) external nonReentrant {
        require(!loans[loanId].isActive, "Loan already funded");
        uint256 amount = loans[loanId].amount;
        
        lendingToken.transferFrom(msg.sender, address(this), amount);
        loans[loanId].lender = msg.sender;
        loans[loanId].isActive = true;
        loans[loanId].startTime = block.timestamp;
    }

    function repayLoan(uint256 loanId) external nonReentrant {
        Loan storage loan = loans[loanId];
        require(loan.borrower == msg.sender, "Not borrower");
        require(loan.isActive, "Loan not active");
        
        uint256 totalAmount = loan.amount + (loan.amount * loan.interestRate) / 10000;
        lendingToken.transferFrom(msg.sender, loan.lender, totalAmount);
        
        loan.isRepaid = true;
        loan.isActive = false;
        
        // Update credit score
        CreditScore storage score = creditScores[msg.sender];
        score.totalLoans++;
        score.repaidLoans++;
        score.score += 50;
        score.lastUpdated = block.timestamp;
    }

    function updateCreditScore(
        address user,
        uint256 newScore
    ) external {
        // In production, this would be restricted to oracles
        creditScores[user].score = newScore;
        creditScores[user].lastUpdated = block.timestamp;
    }

    function calculateInterest(uint256 loanId) public view returns (uint256) {
        Loan memory loan = loans[loanId];
        return (loan.amount * loan.interestRate) / 10000;
    }
}
