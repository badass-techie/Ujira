// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract DividendsPayout {
    address private owner;
    uint256 private constant TRANSACTION_FEE = 3; // 3% transaction fee

    constructor() {
        owner = msg.sender;
    }

    struct Shareholder {
        address shareholderAddress;
        address companyAddress;
        string name;
        uint256 shares;
    }

    struct Company {
        address companyAddress;
        string name;
        string symbol;
        string description;
        uint256 balance;
        uint256 totalShares;
        uint256 lastPayoutTimestamp;
        uint256 payoutInterval;
    }

    address[] private companyAddresses;
    mapping(address => Company) private companies;
    mapping(address => Shareholder) private shareholders;
    mapping(address => address[]) private companyShareholders;

    event Deposit(address indexed companyAddress, uint256 amount, uint256 transactionFee, uint256 timestamp);
    event Payout(address indexed companyAddress, uint256 totalAmount, uint256 transactionFee, uint256[] amounts, uint256 timestamp);    // amounts are for each shareholder in the same order as companyShareholders
    event Withdraw(address indexed companyAddress, uint256 amount, uint256 transactionFee, uint256 timestamp);

    function addOrChangeCompany(string memory _name, string memory _symbol, string memory _description, uint256 _payoutInterval) public {
        Company storage company = companies[msg.sender];
        if (company.companyAddress == address(0)) {
            // Create if not found
            company.companyAddress = msg.sender;
            company.name = _name;
            company.symbol = _symbol;
            company.description = _description;
            company.payoutInterval = _payoutInterval * 1 seconds;
            company.lastPayoutTimestamp = block.timestamp;
            companyAddresses.push(msg.sender);
        } else {    
            // Update if found
            company.name = _name;
            company.symbol = _symbol;
            company.description = _description;
            company.payoutInterval = _payoutInterval * 1 seconds;
        }
    }

    function addOrChangeShareholder(string memory _name, address _shareholderAddress, uint256 _shares) public {
        require(companies[msg.sender].companyAddress != address(0), "Company does not exist.");
        require(_shareholderAddress != address(0), "Shareholder address cannot be 0.");
        require(_shares > 0, "Shares must be greater than 0.");
        Shareholder storage shareholder = shareholders[_shareholderAddress];
        if (shareholder.shareholderAddress == address(0)) {
            // Create if not found
            shareholder.shareholderAddress = _shareholderAddress;
            shareholder.companyAddress = msg.sender;
            shareholder.name = _name;
            shareholder.shares = _shares;
            companies[msg.sender].totalShares += _shares;
            companyShareholders[msg.sender].push(_shareholderAddress);
        } else {
            // Update if found
            companies[msg.sender].totalShares -= shareholder.shares;
            shareholder.companyAddress = msg.sender;
            shareholder.name = _name;
            shareholder.shares = _shares;
            companies[msg.sender].totalShares += _shares;
        }
    }

    function getCompanies() public view returns(address[] memory) {
        return companyAddresses;
    }

    function getCompany(address _companyAddress) public view returns(Company memory) {
        Company memory company = companies[_companyAddress];
        require(company.companyAddress != address(0), "Company does not exist.");
        return company;
    }

    function getShareholders(address _companyAddress) public view returns(address[] memory) {
        return companyShareholders[_companyAddress];
    }

    function getShareholder(address _shareholderAddress) public view returns(Shareholder memory) {
        Shareholder memory shareholder = shareholders[_shareholderAddress];
        require(shareholder.shareholderAddress != address(0), "Shareholder does not exist.");
        return shareholder;
    }

    function removeShareholder(address _shareholderAddress) public {
        Company storage company = companies[msg.sender];
        Shareholder storage shareholder = shareholders[_shareholderAddress];

        require(company.companyAddress != address(0), "Company does not exist.");
        require(shareholder.shareholderAddress != address(0), "Shareholder does not exist.");

        company.totalShares -= shareholder.shares;
        for (uint256 i = 0; i < companyShareholders[msg.sender].length; i++) {
            if (companyShareholders[msg.sender][i] == _shareholderAddress) {
                companyShareholders[msg.sender][i] = companyShareholders[msg.sender][companyShareholders[msg.sender].length - 1];
                companyShareholders[msg.sender].pop();
                break;
            }
        }
        delete shareholders[_shareholderAddress];
    }

    function removeCompany() public {
        Company storage company = companies[msg.sender];
        require(company.companyAddress != address(0), "Company does not exist.");

        // Send balance to owner
        uint256 balance = company.balance;
        uint256 transactionFee = balance * TRANSACTION_FEE / 100;
        balance -= transactionFee;
        payable(msg.sender).transfer(balance);  // Transfer balance back to company
        payable(owner).transfer(transactionFee);    // Transfer transaction fee to us
        emit Withdraw(msg.sender, balance, transactionFee, block.timestamp);

        // Remove shareholders
        for (uint256 i = 0; i < companyShareholders[msg.sender].length; i++) {
            removeShareholder(companyShareholders[msg.sender][i]);
        }

        // Remove company
        for (uint256 i = 0; i < companyAddresses.length; i++) {
            if (companyAddresses[i] == msg.sender) {
                companyAddresses[i] = companyAddresses[companyAddresses.length - 1];
                companyAddresses.pop();
                break;
            }
        }
        delete companies[msg.sender];
    }

    function deposit() external payable {
        Company storage company = companies[msg.sender];
        require(company.companyAddress != address(0), "Company does not exist.");
        require(msg.value > 0, "Amount must be greater than 0.");
        // if any require statement fails, the transaction will revert automatically so we don't need to manually transfer back the tokens

        uint256 amount = msg.value;
        uint256 transactionFee = amount * TRANSACTION_FEE / 100;
        amount -= transactionFee;
        company.balance += amount;
        payable(owner).transfer(transactionFee);    // Transfer transaction fee to us
        emit Deposit(msg.sender, amount, transactionFee, block.timestamp);
    }

    function payout(uint256 _amount) external {
        Company storage company = companies[msg.sender];
        require(company.companyAddress != address(0), "Company does not exist.");
        require(company.balance >= _amount, "Balance must be greater than amount.");
        require(block.timestamp >= company.lastPayoutTimestamp + company.payoutInterval, "Payout interval not reached.");
        require(companyShareholders[msg.sender].length > 0, "No shareholders.");

        uint256 totalShares = company.totalShares;
        uint256 totalPayout = _amount;
        uint256 transactionFee = totalPayout * TRANSACTION_FEE / 100;
        totalPayout -= transactionFee;

        uint256[] memory payouts = new uint256[](companyShareholders[msg.sender].length);
        for (uint256 i = 0; i < companyShareholders[msg.sender].length; i++) {
            Shareholder storage shareholder = shareholders[companyShareholders[msg.sender][i]];
            uint256 amount = totalPayout * shareholder.shares / totalShares;
            payable(shareholder.shareholderAddress).transfer(amount);   // Transfer tokens to shareholder
            company.balance -= amount;
            payouts[i] = amount;
        }

        payable(owner).transfer(transactionFee);    // Transfer transaction fee to us
        company.balance -= transactionFee;
        company.lastPayoutTimestamp = block.timestamp;

        emit Payout(msg.sender, totalPayout, transactionFee, payouts, block.timestamp);
    }

    function withdraw(uint256 _amount) external {
        Company storage company = companies[msg.sender];
        require(company.companyAddress != address(0), "Company does not exist.");
        require(company.balance >= _amount, "Balance must be greater than amount.");
        uint256 transactionFee = _amount * TRANSACTION_FEE / 100;
        _amount -= transactionFee;
        payable(msg.sender).transfer(_amount);  // Transfer tokens to company
        company.balance -= _amount;
        payable(owner).transfer(transactionFee);    // Transfer transaction fee to us
        emit Withdraw(msg.sender, _amount, transactionFee, block.timestamp);
    }
}
