
pragma solidity ^0.8.0;

contract CollateralizedLoan {
    address public owner;
    uint256 public interestRate; // in percentage (e.g., 5 means 5%)
    uint256 public loanDuration; // in seconds
    
    struct Loan {
        uint256 collateralAmount;
        uint256 loanAmount;
        uint256 startTime;
        bool isActive;
    }
    
    mapping(address => Loan) public loans;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        interestRate = 5; // Default interest rate
        loanDuration = 30 days; // Default loan duration
    }

    function depositCollateral() external payable {
        require(msg.value > 0, "Collateral must be greater than 0");
        require(!loans[msg.sender].isActive, "Existing loan must be repaid first");
        
        uint256 loanAmount = msg.value / 2; // Loan is 50% of collateral
        loans[msg.sender] = Loan(msg.value, loanAmount, block.timestamp, true);
    }
    
    function withdrawLoan() external {
        Loan storage loan = loans[msg.sender];
        require(loan.isActive, "No active loan");
        
        payable(msg.sender).transfer(loan.loanAmount);
    }
    
    function repayLoan() external payable {
        Loan storage loan = loans[msg.sender];
        require(loan.isActive, "No active loan");
        
        uint256 interest = (loan.loanAmount * interestRate) / 100;
        uint256 totalRepayment = loan.loanAmount + interest;
        require(msg.value >= totalRepayment, "Insufficient repayment amount");
        
        loan.isActive = false;
        payable(msg.sender).transfer(loan.collateralAmount - totalRepayment);
    }
    
    function liquidateLoan(address borrower) external onlyOwner {
        Loan storage loan = loans[borrower];
        require(loan.isActive, "No active loan");
        require(block.timestamp >= loan.startTime + loanDuration, "Loan not due yet");
        
        loan.isActive = false;
    }
}
