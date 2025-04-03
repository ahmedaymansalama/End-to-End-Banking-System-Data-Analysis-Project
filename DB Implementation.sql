
CREATE TABLE District (
    DistrictID INT PRIMARY KEY,
    DistrictNumber INT NOT NULL,
    Region VARCHAR(30) NOT NULL,
    CreatedDate DATETIME NOT NULL,
);  

----------------------------------------------------------------
CREATE TABLE Branch (
    BranchID INT PRIMARY KEY,
    BranchName VARCHAR(30) NOT NULL UNIQUE,
	BranchType VARCHAR(10) CHECK (BranchType IN ('Credit', 'Retail')) NOT NULL,
    DistrictID INT,
    OpeningDate DATETIME NOT NULL,
    ManagerID INT    
);
ALTER TABLE Branch ADD CONSTRAINT FK_District_Branch FOREIGN KEY (DistrictID) REFERENCES District(DistrictID) ON DELETE SET NULL;
ALTER TABLE Branch ADD CONSTRAINT FK_Employee_Branch FOREIGN KEY (ManagerID) REFERENCES Employee(EmployeeID) ON DELETE SET NULL

------------------------------------------------------------------
CREATE TABLE Department (
    DepartmentID INT PRIMARY KEY,
    DepartmentName VARCHAR(200) NOT NULL,
    BranchID INT NOT NULL,
	ManagerID INT,
    DeparmentCapacity INT,
	Email VARCHAR(200) UNIQUE,
	Phone VARCHAR(20),
    FOREIGN KEY (BranchID) REFERENCES Branch(BranchID) ON DELETE CASCADE,
);
ALTER TABLE Department ADD CONSTRAINT FK_Department_Employee FOREIGN KEY(ManagerID) REFERENCES Employee(EmployeeID) ON DELETE SET NULL
ALTER TABLE Department ADD CONSTRAINT UN_Name_BranchID UNIQUE(BranchID,DepartmentName)


------------------------------------------------------------------

CREATE TABLE Employee (
    EmployeeID INT PRIMARY KEY,
	EmployeeNum INT NOT NULL UNIQUE,
    Name VARCHAR(200) NOT NULL,
    Position VARCHAR(200) NOT NULL,
    Salary DECIMAL(10,2) NOT NULL CHECK (Salary > 0),
	Gender VARCHAR(10) CHECK (Gender IN ('Male', 'Female')) NOT NULL,
	Gov VARCHAR(20) NOT NULL ,
	City VARCHAR(30) NOT NULL,
	Address VARCHAR(80) NOT NULL,
	DOB DATE NOT NULL,
    HireDate DATETIME NOT NULL,
	PerformanceScore INT CHECK (PerformanceScore BETWEEN 0 AND 100),
    BranchID INT NOT NULL,
    DepartmentID INT NOT NULL,
    Status VARCHAR(15) NOT NULL CHECK (Status IN ('Active', 'Inactive', 'Terminated')),
);
ALTER TABLE Employee ADD CONSTRAINT FK_Branch FOREIGN KEY (BranchID) REFERENCES Branch(BranchID);
ALTER TABLE Employee ADD CONSTRAINT FK_Department FOREIGN KEY (DepartmentID) REFERENCES Department(DepartmentID);
ALTER TABLE Employee ADD CONSTRAINT chk_EmployeeNum_Length CHECK (EmployeeNum BETWEEN 100000 AND 999999)






------------------------------------------------------------------

CREATE TABLE ClientSegment (
    SegmentID INT PRIMARY KEY,
    SegmentName VARCHAR(255) NOT NULL UNIQUE,
	MinDeposit INT NOT NULL,
	MaxDeposit INT NOT NULL

);

------------------------------------------------------------------
CREATE TABLE Client (
    ClientID INT PRIMARY KEY,
	ClientNum BIGINT NOT NULL UNIQUE,
    Name VARCHAR(255) NOT NULL,
    Gender VARCHAR(10) CHECK (Gender IN ('Male', 'Female')) NOT NULL,
	DOB DATE,
	Gov VARCHAR(25) NOT NULL,
	City VARCHAR(30) NOT NULL,
	Address VARCHAR(80) NOT NULL,
    Phone VARCHAR(20) UNIQUE NOT NULL,
    Email VARCHAR(200) NOT NULL,
    SegmentID INT NOT NULL,
    BranchID INT NOT NULL,
    RegistrationDate DATETIME NOT NULL,
);
ALTER TABLE Client ADD CONSTRAINT FK_ClientSegment FOREIGN KEY (SegmentID) REFERENCES ClientSegment(SegmentID);
ALTER TABLE Client ADD CONSTRAINT FK_Branch_Client FOREIGN KEY (BranchID) REFERENCES Branch(BranchID);
ALTER TABLE Client ADD CONSTRAINT chk_ClientNum_Length CHECK (ClientNum BETWEEN 1000000000 AND 9999999999);

------------------------------------------------------------------

CREATE TABLE Service (
    ServiceID INT PRIMARY KEY,
    ServiceName VARCHAR(150) NOT NULL ,
    Description TEXT NOT NULL,
    Fee DECIMAL(10,2) CHECK (Fee >= 0) NOT NULL,
	Nature VARCHAR(10) NOT NULL,
	AmountFlag  VARCHAR(10) CHECK (AmountFlag IN ('Yes', 'NO')) NOT NULL,
	ProductID INT NOT NULL
);
ALTER TABLE Service Add CONSTRAINT FK_Master_Service FOREIGN KEY (ProductID) REFERENCES ProductMaster(ProductID);


------------------------------------------------------------------

create TABLE Transactions (
    TransactionID INT PRIMARY KEY,
	ReferenceNum INT NOT NULL UNIQUE,
    ClientID INT NOT NULL,
    ServiceID INT,
    EmployeeID INT,
    Amount DECIMAL(15,2) CHECK (Amount > 0) NOT NULL,
    TransactionDate DATETIME NOT NULL,
    Status VARCHAR(15) NOT NULL CHECK (Status IN ('Completed', 'Pending', 'Failed')),
);
ALTER TABLE Transactions ADD CONSTRAINT FK_Client_Tr FOREIGN KEY (ClientID) REFERENCES Client(ClientID) ON DELETE CASCADE;
ALTER TABLE Transactions ADD CONSTRAINT FK_Service_Tr FOREIGN KEY (ServiceID) REFERENCES Service(ServiceID) ON DELETE SET NULL;
ALTER TABLE Transactions ADD CONSTRAINT FK_Employee_Tr FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID) ON DELETE SET NULL;
ALTER TABLE Transactions ADD CONSTRAINT DF_TransactionDate DEFAULT GETDATE() FOR TransactionDate;

------------------------------------------------------------------

CREATE TABLE EmployeeTarget (
    EmployeeID INT NOT NULL,
	Year SMALLINT NOT NULL,
	LoanTarget DECIMAL(15,2) CHECK (LoanTarget > 0),
	AccountTarget INT CHECK (AccountTarget > 0),
	WalletTarget INT CHECK (WalletTarget > 0),
	CardTarget INT CHECK (CardTarget > 0),
	OBTarget INT CHECK (OBTarget > 0),
	CertificateTarget INT CHECK (CertificateTarget > 0)

);
ALTER TABLE EmployeeTarget ADD CONSTRAINT PK_EmployeeID_Year PRIMARY KEY (EmployeeID, Year ) 
ALTER TABLE EmployeeTarget ADD CONSTRAINT FK_Employee_Target FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID) ON DELETE CASCADE;
ALTER TABLE EmployeeTarget ADD CONSTRAINT FK_ProductMaster_Target FOREIGN KEY (ProductID) REFERENCES ProductMaster(ProductID) ON DELETE CASCADE

------------------------------------------------------------------

CREATE TABLE ProductMaster (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(200) NOT NULL UNIQUE,
    ProductType VARCHAR(30) NOT NULL,
    Status VARCHAR(15) NOT NULL CHECK (Status IN ('Active', 'Inactive'))
);


------------------------------------------------------------------

CREATE TABLE Loan (
    LoanID INT PRIMARY KEY,
    ClientID INT NOT NULL,
	ProductID INT NOT NULL,
	EmployeeID INT NOT NULL,
    LoanAmount DECIMAL(15,2) CHECK (LoanAmount > 0) NOT NULL,
    InterestRate DECIMAL(5,2) CHECK (InterestRate >= 0) NOT NULL,
    PayoutInterst INT CHECK (PayoutInterst > 0) NOT NULL,
    IssueDate DATETIME NOT NULL,
    MaturityDate DATETIME NOT NULL,
    Status VARCHAR(15) NOT NULL CHECK (Status IN ('Active', 'Closed')),
);
ALTER TABLE Loan ADD CONSTRAINT FK_Client_Loan FOREIGN KEY (ClientID) REFERENCES Client(ClientID) ON DELETE CASCADE;
ALTER TABLE Loan ADD CONSTRAINT FK_Master_Loan FOREIGN KEY (ProductID) REFERENCES ProductMaster(ProductID);
ALTER TABLE Loan ADD CONSTRAINT FK_Emp_Loan FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)

------------------------------------------------------------------

CREATE TABLE Account (
    AccountID INT PRIMARY KEY,
	ClientID INT,
    AccountNumber VARCHAR(20) NOT NULL UNIQUE,
	ProductID INT NOT NULL,
	EmployeeID INT NOT NULL,
    Balance DECIMAL(15,2) DEFAULT 0 CHECK (Balance >= 0),
    OpenDate DATETIME NOT NULL,
    Status VARCHAR(50) NOT NULL CHECK (Status IN ('Active', 'Inactive', 'Closed')),	
);
ALTER TABLE Account ADD CONSTRAINT FK_Client_Account FOREIGN KEY (ClientID) REFERENCES Client(ClientID) ON DELETE NO ACTION;
ALTER TABLE Account ADD CONSTRAINT FK_Master_Account FOREIGN KEY (ProductID) REFERENCES ProductMaster(ProductID);
ALTER TABLE Account ADD CONSTRAINT FK_Emp_Account FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)

------------------------------------------------------------------
  
CREATE TABLE Wallet (
    WalletID INT PRIMARY KEY,
    ClientID INT NOT NULL,
	ProductID INT NOT NULL,
	EmployeeID INT NOT NULL,
	Phone VARCHAR(20) UNIQUE NOT NULL,
    Balance DECIMAL(15,2) CHECK (Balance >= 0) DEFAULT 0,
    ActivationDate DATETIME NOT NULL,
    Status VARCHAR(15) NOT NULL CHECK (Status IN ('Active', 'Inactive')),
);
ALTER TABLE Wallet ADD CONSTRAINT FK_Client_Wallet FOREIGN KEY (ClientID) REFERENCES Client(ClientID) ON DELETE CASCADE;
ALTER TABLE Wallet ADD CONSTRAINT FK_Master_Wallet FOREIGN KEY (ProductID) REFERENCES ProductMaster(ProductID);
ALTER TABLE Wallet ADD CONSTRAINT FK_Emp_Wallet FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)

------------------------------------------------------------------

CREATE TABLE Card (
    CardID INT PRIMARY KEY,
    ClientID INT NOT NULL,
	ProductID INT NOT NULL,
	EmployeeID INT NOT NULL,
    CardNumber VARCHAR(20) NOT NULL UNIQUE,
    ExpiryDate DATETIME NOT NULL,
    CVV INT CHECK (CVV BETWEEN 100 AND 999) NOT NULL,
    Status VARCHAR(15) NOT NULL CHECK (Status IN ('Active', 'Blocked', 'Expired')),
);
ALTER TABLE Card ADD CONSTRAINT FK_Client_Card FOREIGN KEY (ClientID) REFERENCES Client(ClientID) ON DELETE CASCADE;
ALTER TABLE Card ADD CONSTRAINT chk_CardNumber_Length CHECK (LEN(CardNumber) = 16);
ALTER TABLE Card ADD CONSTRAINT chk_CardNumber_Format CHECK (CardNumber NOT LIKE '%[^0-9]%')
ALTER TABLE Card ADD CONSTRAINT FK_Master_Card FOREIGN KEY (ProductID) REFERENCES ProductMaster(ProductID);
ALTER TABLE Card ADD CONSTRAINT FK_Emp_Card FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)

------------------------------------------------------------------

CREATE TABLE Certificate (
    CertificateID INT PRIMARY KEY,
    ClientID INT NOT NULL,
	ProductID INT NOT NULL,
	EmployeeID INT NOT NULL,
    Amount DECIMAL(15,2) CHECK (Amount > 0) NOT NULL,
    InterestRate DECIMAL(5,2) CHECK (InterestRate >= 0) NOT NULL,
    PayoutInterst INT CHECK (PayoutInterst > 0) NOT NULL,
    IssueDate DATETIME NOT NULL,
    MaturityDate DATETIME NOT NULL,
	Status VARCHAR(15) NOT NULL CHECK (Status IN ('Active', 'Inactive'))
);
ALTER TABLE Certificate ADD CONSTRAINT FK_Client_Certificate FOREIGN KEY (ClientID) REFERENCES Client(ClientID) ON DELETE CASCADE;
ALTER TABLE Certificate ADD CONSTRAINT FK_Master_Certificate FOREIGN KEY (ProductID) REFERENCES ProductMaster(ProductID);
ALTER TABLE Certificate ADD CONSTRAINT FK_Emp_Certificate FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)

------------------------------------------------------------------

CREATE TABLE OnlineBanking (
    OnlineBankingID INT PRIMARY KEY,
    ClientID INT NOT NULL,
	ProductID INT NOT NULL,
	EmployeeID INT NOT NULL,
	SubscriptionDate DATE NOT NULL ,
    Status VARCHAR(15) NOT NULL CHECK (Status IN ('Active', 'Inactive')),
);
ALTER TABLE OnlineBanking ADD CONSTRAINT FK_Client_OnlineBanking FOREIGN KEY (ClientID) REFERENCES Client(ClientID) ON DELETE CASCADE;
ALTER TABLE OnlineBanking ADD CONSTRAINT FK_Master_OnlineBanking FOREIGN KEY (ProductID) REFERENCES ProductMaster(ProductID);
ALTER TABLE OnlineBanking ADD CONSTRAINT FK_Emp_OnlineBanking FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID)

------------------------------------------------------------------

CREATE TABLE ATM (
    ATMID INT PRIMARY KEY,
	ATMNum INT NOT NULL,
    BranchID INT NOT NULL,
	CashCapacity INT NOT NULL,
	InstallationDate Date NOT NULL,
	LastMaintenance Date NOT NULL,
	Status VARCHAR(15) NOT NULL CHECK (Status IN ('Active', 'Inactive'))

);
ALTER TABLE ATM ADD CONSTRAINT FK_Branch_ATM FOREIGN KEY (BranchID) REFERENCES Branch(BranchID) ON DELETE CASCADE

------------------------------------------------------------------

CREATE TABLE Expenses (
    ExpenseID INT PRIMARY KEY,
    ExpenseType VARCHAR(255) NOT NULL,
    Amount DECIMAL(15,2) CHECK (Amount >= 0) NOT NULL,
    BranchID INT NOT NULL,
    ExpenseDate DATETIME NOT NULL,
	InvoiceNum varchar(60),
	Vendor VARCHAR(100) NOT NULL
);
ALTER TABLE Expenses ADD CONSTRAINT FK_Branch_Expenses FOREIGN KEY (BranchID) REFERENCES Branch(BranchID) ON DELETE CASCADE

