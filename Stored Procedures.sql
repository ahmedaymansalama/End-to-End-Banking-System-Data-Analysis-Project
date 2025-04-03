-- ============================================
-- Insert Procedure: Adds a new District
-- ============================================
CREATE PROCEDURE InsertDistrict
    @DistrictNumber INT,
    @Region VARCHAR(30)
AS
BEGIN
    DECLARE @NewDistrictID INT;

    -- Get the last DistrictID and increment it
    SELECT @NewDistrictID = ISNULL(MAX(DistrictID), 0) + 1 FROM District;

    INSERT INTO District (DistrictID, DistrictNumber, Region, CreatedDate)
    VALUES (@NewDistrictID, @DistrictNumber, @Region, GETDATE());
END;
GO

-- ============================================
-- Update Procedure: Updates an existing District
-- ============================================
CREATE PROCEDURE UpdateDistrict
    @DistrictID INT,
    @DistrictNumber INT,
    @Region VARCHAR(30)
AS
BEGIN
    UPDATE District
    SET DistrictNumber = @DistrictNumber,
        Region = @Region
    WHERE DistrictID = @DistrictID;
END;
GO

-- ============================================
-- Delete Procedure: Deletes a District
-- Options: Move branches to another District or remove the relation
-- ============================================
CREATE PROCEDURE DeleteDistrict
    @DistrictID INT,
    @NewDistrictID INT = NULL -- If provided, move branches; otherwise, remove relation
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Branch WHERE DistrictID = @DistrictID)
    BEGIN
        IF @NewDistrictID IS NOT NULL
        BEGIN
            -- Move branches to another district
            UPDATE Branch SET DistrictID = @NewDistrictID WHERE DistrictID = @DistrictID;
        END
        ELSE
        BEGIN
            -- Remove the relation between branches and this district
            UPDATE Branch SET DistrictID = NULL WHERE DistrictID = @DistrictID;
        END
    END

    -- Delete the district after handling branches
    DELETE FROM District WHERE DistrictID = @DistrictID;
END;
GO

-- ============================================
-- Select Procedure: Retrieve Districts
-- Options: Get all districts or a specific one
-- ============================================
Alter PROCEDURE SelectDistrict
    
	 @DistrictNumber INT,
    @Region VARCHAR(30)
AS
BEGIN
    -- If NULL, returns all districts,
    IF @DistrictNumber IS NULL or @Region Is Null
        SELECT * FROM District;
    ELSE
        SELECT * FROM District WHERE DistrictNumber = @DistrictNumber and Region =@Region ;
END;
GO
--------------------------------------------------------------------------Branch
CREATE PROCEDURE InsertBranch
    @BranchName VARCHAR(30),
    @BranchType VARCHAR(10),
    @DistrictID INT,
    @OpeningDate DATETIME,
    @ManagerName VARCHAR(100), -- يأخذ اسم المدير بدلاً من ID
	@EmployeeNum int 
AS
BEGIN
    DECLARE @NewBranchID INT;
    DECLARE @ManagerID INT;

    DECLARE @CurrentPosition VARCHAR(50);

    -- Get the last BranchID and increment it
    SELECT @NewBranchID = ISNULL(MAX(BranchID), 0) + 1 FROM Branch;

    -- Retrieve the ManagerID and Position using ManagerName
    SELECT @ManagerID = EmployeeID, @CurrentPosition = Position 
    FROM Employee 
    WHERE Name = @ManagerName  and EmployeeNum=@EmployeeNum;

    -- Ensure the Manager exists
    IF @ManagerID IS NULL
    BEGIN
        PRINT 'Error: Manager not found!';
        RETURN;
    END

    -- If the employee is not a Manager, update their position
    IF @CurrentPosition <> 'Manager'
    BEGIN
        UPDATE Employee 
        SET Position = 'Manager'
        WHERE EmployeeID = @ManagerID;
    END

    -- Insert the new branch
    INSERT INTO Branch (BranchID, BranchName, BranchType, DistrictID, OpeningDate, ManagerID)
    VALUES (@NewBranchID, @BranchName, @BranchType, @DistrictID, @OpeningDate, @ManagerID);
END;
GO
----Update 
CREATE PROCEDURE UpdateBranch
    @BranchName VARCHAR(100),
    @NewManagerName VARCHAR(100),
    @NewDistrictID INT
AS
BEGIN
    DECLARE @NewManagerID INT;
    
    -- Get the new Manager ID
    SELECT @NewManagerID = EmployeeID FROM Employee WHERE Name = @NewManagerName;
    
    -- Ensure the Manager exists
    IF @NewManagerID IS NULL
    BEGIN
        PRINT 'Error: New Manager not found!';
        RETURN;
    END

    -- Update the branch with the new Manager and District
    UPDATE Branch
    SET ManagerID = @NewManagerID, DistrictID = @NewDistrictID
    WHERE BranchName = @BranchName;
END;
GO
--------------Delete 
CREATE PROCEDURE DeleteBranch
    @BranchName VARCHAR(30),
    @DistrictName VARCHAR(50)
AS
BEGIN
    DECLARE @BranchID INT, @DistrictID INT;
    
    -- Get the DistrictID
    SELECT @DistrictID = DistrictID FROM District WHERE DistrictName = @DistrictName;
    
    -- Get the BranchID
    SELECT @BranchID = BranchID FROM Branch WHERE BranchName = @BranchName AND DistrictID = @DistrictID;

    -- Ensure the branch exists
    IF @BranchID IS NULL
    BEGIN
        PRINT 'Error: Branch not found!';
        RETURN;
    END

    -- Check if the branch has any employees
    IF EXISTS (SELECT 1 FROM Employee WHERE BranchID = @BranchID)
    BEGIN
        PRINT 'Error: Cannot delete branch. Employees exist!';
        RETURN;
    END

    -- Check if the branch has any departments
    IF EXISTS (SELECT 1 FROM Department WHERE BranchID = @BranchID)
    BEGIN
        PRINT 'Error: Cannot delete branch. Departments exist!';
        RETURN;
    END

    -- If no dependencies, delete the branch
    DELETE FROM Branch WHERE BranchID = @BranchID;
    
    PRINT 'Branch deleted successfully.';
END;
GO

--------------select 
CREATE PROCEDURE GetBranchDetails
    @Branchname  Varchar(100)
AS
BEGIN
    SELECT 
        B.BranchName, 
        B.BranchType, 
        D.DistrictID, 
        E.Name AS ManagerName, 
        E.Position AS ManagerPosition
    FROM Branch B
    LEFT JOIN District D ON B.DistrictID = D.DistrictID
    LEFT JOIN Employee E ON B.ManagerID = E.EmployeeID
    WHERE B.Branchname = @Branchname;
END;
GO

----------------
------------------
CREATE PROCEDURE InsertDepartment
    @DepartmentName VARCHAR(200),
    @BranchName VARCHAR(30),
    @ManagerName VARCHAR(100) = NULL, -- Manager is optional
    @DepartmentCapacity INT = NULL,
    @Email VARCHAR(200) = NULL,
    @Phone VARCHAR(20) = NULL
AS
BEGIN
    DECLARE @BranchID INT, @ManagerID INT;

    -- Get BranchID
    SELECT @BranchID = BranchID FROM Branch WHERE BranchName = @BranchName;

    IF @BranchID IS NULL
    BEGIN
        PRINT 'Error: Branch not found!';
        RETURN;
    END

    -- If ManagerName is provided, get ManagerID
    IF @ManagerName IS NOT NULL
    BEGIN
        SELECT @ManagerID = EmployeeID FROM Employee WHERE Name = @ManagerName AND BranchID = @BranchID;

        IF @ManagerID IS NULL
        BEGIN
            PRINT 'Error: Manager not found in this branch!';
            RETURN;
        END
    END

    -- Insert department
    INSERT INTO Department (DepartmentName, BranchID, ManagerID, DeparmentCapacity, Email, Phone)
    VALUES (@DepartmentName, @BranchID, @ManagerID, @DepartmentCapacity, @Email, @Phone);

    PRINT 'Department added successfully.';
END;
GO
--------------Update
CREATE PROCEDURE UpdateDepartment
    @DepartmentName VARCHAR(200),
    @BranchName VARCHAR(30),
    @NewManagerName VARCHAR(100) = NULL,
    @NewCapacity INT = NULL,
    @NewEmail VARCHAR(200) = NULL,
    @NewPhone VARCHAR(20) = NULL
AS
BEGIN
    DECLARE @BranchID INT, @DepartmentID INT, @NewManagerID INT;

    -- Get BranchID
    SELECT @BranchID = BranchID FROM Branch WHERE BranchName = @BranchName;

    -- Get DepartmentID
    SELECT @DepartmentID = DepartmentID FROM Department WHERE DepartmentName = @DepartmentName AND BranchID = @BranchID;

    IF @DepartmentID IS NULL
    BEGIN
        PRINT 'Error: Department not found!';
        RETURN;
    END

    -- If ManagerName is provided, get ManagerID
    IF @NewManagerName IS NOT NULL
    BEGIN
        SELECT @NewManagerID = EmployeeID FROM Employee WHERE Name = @NewManagerName AND BranchID = @BranchID;

        IF @NewManagerID IS NULL
        BEGIN
            PRINT 'Error: New manager not found in this branch!';
            RETURN;
        END
    END

    -- Update Department
    UPDATE Department
    SET 
        ManagerID = COALESCE(@NewManagerID, ManagerID),
        DeparmentCapacity = COALESCE(@NewCapacity, DeparmentCapacity),
        Email = COALESCE(@NewEmail, Email),
        Phone = COALESCE(@NewPhone, Phone)
    WHERE DepartmentID = @DepartmentID;

    PRINT 'Department updated successfully.';
END;
GO
--------------Delete
CREATE PROCEDURE DeleteDepartment
    @DepartmentName VARCHAR(200),
    @BranchName VARCHAR(30)
AS
BEGIN
    DECLARE @BranchID INT, @DepartmentID INT;

    -- Get BranchID
    SELECT @BranchID = BranchID FROM Branch WHERE BranchName = @BranchName;

    -- Get DepartmentID
    SELECT @DepartmentID = DepartmentID FROM Department WHERE DepartmentName = @DepartmentName AND BranchID = @BranchID;

    IF @DepartmentID IS NULL
    BEGIN
        PRINT 'Error: Department not found!';
        RETURN;
    END

    -- Check if department has employees
    IF EXISTS (SELECT 1 FROM Employee WHERE DepartmentID = @DepartmentID)
    BEGIN
        PRINT 'Error: Cannot delete department. Employees exist!';
        RETURN;
    END

    -- Delete Department
    DELETE FROM Department WHERE DepartmentID = @DepartmentID;

    PRINT 'Department deleted successfully.';
END;
GO
-----------GetDepartment
CREATE PROCEDURE GetDepartment
    @DepartmentName VARCHAR(200),
    @BranchName VARCHAR(30)
AS
BEGIN
    DECLARE @BranchID INT, @DepartmentID INT;

    -- Get BranchID
    SELECT @BranchID = BranchID FROM Branch WHERE BranchName = @BranchName;

    -- Get DepartmentID
    SELECT @DepartmentID = DepartmentID FROM Department WHERE DepartmentName = @DepartmentName AND BranchID = @BranchID;

    IF @DepartmentID IS NULL
    BEGIN
        PRINT 'Error: Department not found!';
        RETURN;
    END

    -- Get Department Details
    SELECT 
        d.DepartmentName,
        b.BranchName,
        e.Name AS ManagerName,
        d.DeparmentCapacity,
        d.Email,
        d.Phone
    FROM Department d
    JOIN Branch b ON d.BranchID = b.BranchID
    LEFT JOIN Employee e ON d.ManagerID = e.EmployeeID
    WHERE d.DepartmentID = @DepartmentID;
END;
GO


---------------------------------------------Employee

CREATE PROCEDURE InsertEmployee
    @EmployeeNum INT,
    @Name VARCHAR(200),
    @Position VARCHAR(200),
    @Salary DECIMAL(10,2),
    @Gender VARCHAR(10),
    @Gov VARCHAR(20) = NULL,
    @City VARCHAR(30) = NULL,
    @Address VARCHAR(80),
    @DOB DATE,
    @HireDate DATETIME,
    @BranchName VARCHAR(30),
    @DepartmentName VARCHAR(200),
    @PerformanceScore INT = NULL,
    @Status VARCHAR(15)
AS
BEGIN
    DECLARE @BranchID INT, @DepartmentID INT;

    -- Check if EmployeeNum is 6 digits
    IF @EmployeeNum < 100000 OR @EmployeeNum > 999999
    BEGIN
        PRINT 'Error: EmployeeNum must be a 6-digit number!';
        RETURN;
    END

    -- Get BranchID
    SELECT @BranchID = BranchID FROM Branch WHERE BranchName = @BranchName;
    IF @BranchID IS NULL
    BEGIN
        PRINT 'Error: Branch not found!';
        RETURN;
    END

    -- Get DepartmentID
    SELECT @DepartmentID = DepartmentID FROM Department WHERE DepartmentName = @DepartmentName AND BranchID = @BranchID;
    IF @DepartmentID IS NULL
    BEGIN
        PRINT 'Error: Department not found in this branch!';
        RETURN;
    END

    -- Insert Employee
    INSERT INTO Employee (EmployeeNum, Name, Position, Salary, Gender, Gov, City, Address, DOB, HireDate, BranchID, DepartmentID, PerformanceScore, Status)
    VALUES (@EmployeeNum, @Name, @Position, @Salary, @Gender, @Gov, @City, @Address, @DOB, @HireDate, @BranchID, @DepartmentID, @PerformanceScore, @Status);

    PRINT 'Employee added successfully.';
END;
GO
---------------------Update
CREATE PROCEDURE UpdateEmployee
    @EmployeeNum INT,
    @NewPosition VARCHAR(200) = NULL,
    @NewSalary DECIMAL(10,2) = NULL,
    @NewPerformanceScore INT = NULL,
    @NewStatus VARCHAR(15) = NULL,
    @NewBranchName VARCHAR(30) = NULL,
    @NewDepartmentName VARCHAR(200) = NULL
AS
BEGIN
    DECLARE @EmployeeID INT, @NewBranchID INT, @NewDepartmentID INT;

    -- Get EmployeeID
    SELECT @EmployeeID = EmployeeID FROM Employee WHERE EmployeeNum = @EmployeeNum;
    IF @EmployeeID IS NULL
    BEGIN
        PRINT 'Error: Employee not found!';
        RETURN;
    END

    -- Get New BranchID if provided
    IF @NewBranchName IS NOT NULL
    BEGIN
        SELECT @NewBranchID = BranchID FROM Branch WHERE BranchName = @NewBranchName;
        IF @NewBranchID IS NULL
        BEGIN
            PRINT 'Error: New branch not found!';
            RETURN;
        END
    END

    -- Get New DepartmentID if provided
    IF @NewDepartmentName IS NOT NULL AND @NewBranchID IS NOT NULL
    BEGIN
        SELECT @NewDepartmentID = DepartmentID FROM Department WHERE DepartmentName = @NewDepartmentName AND BranchID = @NewBranchID;
        IF @NewDepartmentID IS NULL
        BEGIN
            PRINT 'Error: New department not found in this branch!';
            RETURN;
        END
    END

    -- Update Employee
    UPDATE Employee
    SET 
        Position = COALESCE(@NewPosition, Position),
        Salary = COALESCE(@NewSalary, Salary),
        PerformanceScore = COALESCE(@NewPerformanceScore, PerformanceScore),
        Status = COALESCE(@NewStatus, Status),
        BranchID = COALESCE(@NewBranchID, BranchID),
        DepartmentID = COALESCE(@NewDepartmentID, DepartmentID)
    WHERE EmployeeID = @EmployeeID;

    PRINT 'Employee updated successfully.';
END;
GO

--------------Delete
CREATE PROCEDURE DeleteEmployee
    @EmployeeNum INT
AS
BEGIN
    DECLARE @EmployeeID INT, @IsManager BIT;

    -- Get EmployeeID
    SELECT @EmployeeID = EmployeeID FROM Employee WHERE EmployeeNum = @EmployeeNum;
    IF @EmployeeID IS NULL
    BEGIN
        PRINT 'Error: Employee not found!';
        RETURN;
    END

    -- Check if Employee is a manager of a department
    IF EXISTS (SELECT 1 FROM Department WHERE ManagerID = @EmployeeID)
    BEGIN
        PRINT 'Error: Cannot delete. Employee is a department manager!';
        RETURN;
    END

    -- Check if Employee is a manager of a branch
    IF EXISTS (SELECT 1 FROM Branch WHERE ManagerID = @EmployeeID)
    BEGIN
        PRINT 'Error: Cannot delete. Employee is a branch manager!';
        RETURN;
    END

    -- Delete Employee
    DELETE FROM Employee WHERE EmployeeID = @EmployeeID;

    PRINT 'Employee deleted successfully.';
END;
GO
---------------Get Employee
CREATE PROCEDURE GetEmployee
    @EmployeeNum INT
AS
BEGIN
    DECLARE @EmployeeID INT;

    -- Get EmployeeID
    SELECT @EmployeeID = EmployeeID FROM Employee WHERE EmployeeNum = @EmployeeNum;
    IF @EmployeeID IS NULL
    BEGIN
        PRINT 'Error: Employee not found!';
        RETURN;
    END

    -- Get Employee Details
    SELECT 
        e.EmployeeNum,
        e.Name,
        e.Position,
        e.Salary,
        e.Gender,
        e.Gov,
        e.City,
        e.Address,
        e.DOB,
        e.HireDate,
        b.BranchName,
        d.DepartmentName,
        e.PerformanceScore,
        e.Status
    FROM Employee e
    JOIN Branch b ON e.BranchID = b.BranchID
    JOIN Department d ON e.DepartmentID = d.DepartmentID
    WHERE e.EmployeeID = @EmployeeID;
END;
GO
-------------------------Client

CREATE PROCEDURE InsertClient
    @ClientNum INT,
    @Name VARCHAR(255),
    @Gender VARCHAR(10),
    @DOB DATE = NULL,
    @Gov VARCHAR(25),
    @City VARCHAR(30),
    @Address VARCHAR(80),
    @Phone VARCHAR(20),
    @Email VARCHAR(200),
    @SegmentName VARCHAR(50),
    @BranchName VARCHAR(30),
    @RegistrationDate DATETIME
AS
BEGIN
    DECLARE @SegmentID INT, @BranchID INT;

    -- Check if ClientNum is 10 digits
    IF @ClientNum < 1000000000 OR @ClientNum > 9999999999
    BEGIN
        PRINT 'Error: ClientNum must be a 10-digit number!';
        RETURN;
    END

    -- Get SegmentID
    SELECT @SegmentID = SegmentID FROM ClientSegment WHERE SegmentName = @SegmentName;
    IF @SegmentID IS NULL
    BEGIN
        PRINT 'Error: Segment not found!';
        RETURN;
    END

    -- Get BranchID
    SELECT @BranchID = BranchID FROM Branch WHERE BranchName = @BranchName;
    IF @BranchID IS NULL
    BEGIN
        PRINT 'Error: Branch not found!';
        RETURN;
    END

    -- Insert Client
    INSERT INTO Client (ClientNum, Name, Gender, DOB, Gov, City, Address, Phone, Email, SegmentID, BranchID, RegistrationDate)
    VALUES (@ClientNum, @Name, @Gender, @DOB, @Gov, @City, @Address, @Phone, @Email, @SegmentID, @BranchID, @RegistrationDate);

    PRINT 'Client added successfully.';
END;
GO
----------------Update
CREATE PROCEDURE UpdateClient
    @ClientNum INT,
    @NewGov VARCHAR(25) = NULL,
    @NewCity VARCHAR(30) = NULL,
    @NewAddress VARCHAR(80) = NULL,
    @NewPhone VARCHAR(20) = NULL,
    @NewEmail VARCHAR(200) = NULL,
    @NewSegmentName VARCHAR(50) = NULL,
    @NewBranchName VARCHAR(30) = NULL
AS
BEGIN
    DECLARE @ClientID INT, @NewSegmentID INT, @NewBranchID INT;

    -- Get ClientID
    SELECT @ClientID = ClientID FROM Client WHERE ClientNum = @ClientNum;
    IF @ClientID IS NULL
    BEGIN
        PRINT 'Error: Client not found!';
        RETURN;
    END

    -- Get New SegmentID if provided
    IF @NewSegmentName IS NOT NULL
    BEGIN
        SELECT @NewSegmentID = SegmentID FROM ClientSegment WHERE SegmentName = @NewSegmentName;
        IF @NewSegmentID IS NULL
        BEGIN
            PRINT 'Error: New segment not found!';
            RETURN;
        END
    END

    -- Get New BranchID if provided
    IF @NewBranchName IS NOT NULL
    BEGIN
        SELECT @NewBranchID = BranchID FROM Branch WHERE BranchName = @NewBranchName;
        IF @NewBranchID IS NULL
        BEGIN
            PRINT 'Error: New branch not found!';
            RETURN;
        END
    END

    -- Update Client
    UPDATE Client
    SET 
        
        Gov = COALESCE(@NewGov, Gov),
        City = COALESCE(@NewCity, City),
        Address = COALESCE(@NewAddress, Address),
        Phone = COALESCE(@NewPhone, Phone),
        Email = COALESCE(@NewEmail, Email),
        SegmentID = COALESCE(@NewSegmentID, SegmentID),
        BranchID = COALESCE(@NewBranchID, BranchID)
    WHERE ClientID = @ClientID;

    PRINT 'Client updated successfully.';
END;
GO
--------------- GetClient
CREATE PROCEDURE GetClient
    @ClientNum INT
AS
BEGIN
    DECLARE @ClientID INT;

    -- Get ClientID
    SELECT @ClientID = ClientID FROM Client WHERE ClientNum = @ClientNum;
    IF @ClientID IS NULL
    BEGIN
        PRINT 'Error: Client not found!';
        RETURN;
    END

    -- Get Client Details
    SELECT 
        c.ClientNum,
        c.Name,
        c.Gender,
        c.DOB,
        c.Gov,
        c.City,
        c.Address,
        c.Phone,
        c.Email,
        cs.SegmentName,
        b.BranchName,
        c.RegistrationDate
    FROM Client c
    JOIN ClientSegment cs ON c.SegmentID = cs.SegmentID
    JOIN Branch b ON c.BranchID = b.BranchID
    WHERE c.ClientID = @ClientID;
END;
GO
---------------------------------------------------------Service
CREATE PROCEDURE InsertService
    @ServiceName VARCHAR(150),
    @Description TEXT,
    @Fee DECIMAL(10,2),
    @Nature VARCHAR(10),
    @AmountFlag VARCHAR(10),
    @ProductID INT
AS
BEGIN
    DECLARE @NewServiceID INT;

    IF @Fee < 0
    BEGIN
        PRINT 'Error: Fee must be greater than or equal to 0!';
        RETURN;
    END;

    IF @AmountFlag NOT IN ('Yes', 'NO')
    BEGIN
        PRINT 'Error: AmountFlag must be either Yes or NO!';
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM ProductMaster WHERE ProductID = @ProductID)
    BEGIN
        PRINT 'Error: Invalid ProductID!';
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM Service WHERE ServiceName = @ServiceName)
    BEGIN
        PRINT 'Error: Service name already exists!';
        RETURN;
    END;

    SELECT @NewServiceID = ISNULL(MAX(ServiceID), 0) + 1 FROM Service;

    INSERT INTO Service (ServiceID, ServiceName, Description, Fee, Nature, AmountFlag, ProductID)
    VALUES (@NewServiceID, @ServiceName, @Description, @Fee, @Nature, @AmountFlag, @ProductID);

    PRINT 'Service added successfully with ServiceID: ' + CAST(@NewServiceID AS VARCHAR);
END;
GO

CREATE PROCEDURE UpdateService
    @ServiceName VARCHAR(150),
    @NewServiceName VARCHAR(150) = NULL,
    @NewDescription TEXT = NULL,
    @NewFee DECIMAL(10,2) = NULL,
    @NewNature VARCHAR(10) = NULL,
    @NewAmountFlag VARCHAR(10) = NULL,
    @NewProductID INT = NULL
AS
BEGIN
    DECLARE @ServiceID INT;

    SELECT @ServiceID = ServiceID FROM Service WHERE ServiceName = @ServiceName;
    IF @ServiceID IS NULL
    BEGIN
        PRINT 'Error: Service not found!';
        RETURN;
    END;

    IF @NewFee IS NOT NULL AND @NewFee < 0
    BEGIN
        PRINT 'Error: Fee must be greater than or equal to 0!';
        RETURN;
    END;

    IF @NewAmountFlag IS NOT NULL AND @NewAmountFlag NOT IN ('Yes', 'NO')
    BEGIN
        PRINT 'Error: AmountFlag must be either Yes or NO!';
        RETURN;
    END;

    IF @NewProductID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM ProductMaster WHERE ProductID = @NewProductID)
    BEGIN
        PRINT 'Error: Invalid ProductID!';
        RETURN;
    END;

    IF @NewServiceName IS NOT NULL AND EXISTS (SELECT 1 FROM Service WHERE ServiceName = @NewServiceName)
    BEGIN
        PRINT 'Error: New service name already exists!';
        RETURN;
    END;

    UPDATE Service
    SET 
        ServiceName = COALESCE(@NewServiceName, ServiceName),
        Description = COALESCE(@NewDescription, Description),
        Fee = COALESCE(@NewFee, Fee),
        Nature = COALESCE(@NewNature, Nature),
        AmountFlag = COALESCE(@NewAmountFlag, AmountFlag),
        ProductID = COALESCE(@NewProductID, ProductID)
    WHERE ServiceID = @ServiceID;

    PRINT 'Service updated successfully.';
END;
GO

CREATE PROCEDURE DeleteService
    @ServiceID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Service WHERE ServiceID = @ServiceID)
    BEGIN
        PRINT 'Error: Service not found!';
        RETURN;
    END;

    DELETE FROM Service WHERE ServiceID = @ServiceID;

    PRINT 'Service deleted successfully!';
END;
GO

CREATE PROCEDURE GetService
    @ServiceName VARCHAR(150) = NULL
AS
BEGIN
    SELECT ServiceID, ServiceName, Description, Fee, Nature, AmountFlag, ProductID
    FROM Service
    WHERE (@ServiceName IS NULL OR ServiceName = @ServiceName);
END;
GO

------------------------------------- ProductMaster
-- Insert Procedure for ProductMaster
CREATE PROCEDURE InsertProduct (
    @ProductName VARCHAR(200),
    @ProductType VARCHAR(30),
    @Status VARCHAR(15)
)
AS
BEGIN
    DECLARE @NewProductID INT;
    SELECT @NewProductID = ISNULL(MAX(ProductID), 0) + 1 FROM ProductMaster;
    
    INSERT INTO ProductMaster (ProductID, ProductName, ProductType, Status)
    VALUES (@NewProductID, @ProductName, @ProductType, @Status);
END;

-- Update Procedure for ProductMaster
CREATE PROCEDURE UpdateProduct (
    @ProductID INT,
    
    @Status VARCHAR(15)
)
AS
BEGIN
    UPDATE ProductMaster
    SET  Status = @Status
    WHERE ProductID = @ProductID;
END;

-- Delete Procedure for ProductMaster (Prevents deletion if used in another table)
CREATE PROCEDURE DeleteProduct (
    @ProductID INT
)
AS
BEGIN 
   DELETE FROM ProductMaster WHERE ProductID = @ProductID;
END;

-- Select Procedure for ProductMaster
CREATE PROCEDURE GetProduct (
    @ProductName  INT
)
AS
BEGIN
    SELECT * FROM ProductMaster WHERE ProductName = @ProductName;
END;
--------------------------------------------------------transaction
-- Add a new transaction
CREATE PROCEDURE AddTransaction
    @ClientID INT,
    @ServiceID INT = NULL,
    @EmployeeID INT = NULL,
    @Amount DECIMAL(15,2),
    @Status VARCHAR(15)
AS
BEGIN
    DECLARE @NewTransactionID INT;
    SELECT @NewTransactionID = ISNULL(MAX(TransactionID), 0) + 1 FROM Transactions;
    
    INSERT INTO Transactions (TransactionID, ReferenceNum, ClientID, ServiceID, EmployeeID, Amount, TransactionDate, Status)
    VALUES (@NewTransactionID, @NewTransactionID + 100000, @ClientID, @ServiceID, @EmployeeID, @Amount, GETDATE(), @Status);
END;

-- Update a transaction
CREATE PROCEDURE UpdateTransaction
    @TransactionID INT,
    @Status VARCHAR(15) = NULL,
    @Amount DECIMAL(15,2) = NULL
AS
BEGIN
    UPDATE Transactions
    SET Status = ISNULL(@Status, Status),
        Amount = ISNULL(@Amount, Amount)
    WHERE TransactionID = @TransactionID;
END;

-- Delete a transaction (ensuring it exists before deleting)
CREATE PROCEDURE DeleteTransaction
    @TransactionID INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Transactions WHERE TransactionID = @TransactionID)
    BEGIN
        DELETE FROM Transactions WHERE TransactionID = @TransactionID;
    END;
END;

-- Retrieve transaction details
CREATE PROCEDURE GetTransactionDetails
    @ReferenceNum INT = NULL,
    @ClientID INT = NULL
AS
BEGIN
    SELECT T.*, C.Name AS ClientName, S.ServiceName, E.Name AS EmployeeName
    FROM Transactions T
    LEFT JOIN Client C ON T.ClientID = C.ClientID
    LEFT JOIN Service S ON T.ServiceID = S.ServiceID
    LEFT JOIN Employee E ON T.EmployeeID = E.EmployeeID
    WHERE (T.ReferenceNum = @ReferenceNum OR @ReferenceNum IS NULL)
      AND (T.ClientID = @ClientID OR @ClientID IS NULL);
END;

----------------------------------------------------Employee Target

-- Delete Employee Target
CREATE PROCEDURE DeleteEmployeeTarget
    @EmployeeID INT,
    @Year SMALLINT
AS
BEGIN
    DELETE FROM EmployeeTarget WHERE EmployeeID = @EmployeeID AND Year = @Year;
END;
GO

-- Retrieve Employee Target
CREATE PROCEDURE GetEmployeeTarget
    @EmployeeID INT,
    @Year SMALLINT
AS
BEGIN
    SELECT * FROM EmployeeTarget WHERE EmployeeID = @EmployeeID AND Year = @Year;
END;
GO
----------------------------------------Loan
-- Insert into Loan
CREATE PROCEDURE InsertLoan
    @ClientName VARCHAR(255),
    @ProductName VARCHAR(200),
    @EmployeeName VARCHAR(200),
    @LoanAmount DECIMAL(15,2),
    @InterestRate DECIMAL(5,2),
    @PayoutInterst INT,
    @IssueDate DATETIME,
    @MaturityDate DATETIME,
    @Status VARCHAR(15)
AS
BEGIN
    DECLARE @ClientID INT, @ProductID INT, @EmployeeID INT, @NewLoanID INT;
    
    -- Get ClientID, ProductID, EmployeeID
    SELECT @ClientID = ClientID FROM Client WHERE Name = @ClientName;
    SELECT @ProductID = ProductID FROM ProductMaster WHERE ProductName = @ProductName;
    SELECT @EmployeeID = EmployeeID FROM Employee WHERE Name = @EmployeeName;
    
    -- Get new LoanID
    SELECT @NewLoanID = ISNULL(MAX(LoanID), 0) + 1 FROM Loan;
    
    -- Insert Loan
    INSERT INTO Loan (LoanID, ClientID, ProductID, EmployeeID, LoanAmount, InterestRate, PayoutInterst, IssueDate, MaturityDate, Status)
    VALUES (@NewLoanID, @ClientID, @ProductID, @EmployeeID, @LoanAmount, @InterestRate, @PayoutInterst, @IssueDate, @MaturityDate, @Status);
END;

-- Update Loan
CREATE PROCEDURE UpdateLoan
    @LoanID INT,
    @LoanAmount DECIMAL(15,2),
    @InterestRate DECIMAL(5,2),
    @PayoutInterst INT,
    @IssueDate DATETIME,
    @MaturityDate DATETIME,
    @Status VARCHAR(15)
AS
BEGIN
    UPDATE Loan
    SET LoanAmount = @LoanAmount,
        InterestRate = @InterestRate,
        PayoutInterst = @PayoutInterst,
        IssueDate = @IssueDate,
        MaturityDate = @MaturityDate,
        Status = @Status
    WHERE LoanID = @LoanID;
END;

-- تحديث إجراء حذف القرض مع التحقق من ارتباطه بعميل
CREATE PROCEDURE DeleteLoan 
    @LoanID INT
AS
BEGIN
    -- التحقق مما إذا كان القرض مرتبطًا بعميل
    IF EXISTS (SELECT 1 FROM Loan WHERE LoanID = @LoanID AND ClientID IS NOT NULL)
    BEGIN
        PRINT 'Cannot delete loan because it is linked to a client.';
        RETURN;
    END

    -- حذف القرض إذا لم يكن مرتبطًا بعميل
    DELETE FROM Loan WHERE LoanID = @LoanID;
    PRINT 'Loan deleted successfully.';
END;
GO


-- Select Loan Details
CREATE PROCEDURE GetLoanDetails
AS
BEGIN
    SELECT L.LoanID, C.Name AS ClientName, P.ProductName, E.Name AS EmployeeName, 
           L.LoanAmount, L.InterestRate, L.PayoutInterst, L.IssueDate, L.MaturityDate, L.Status
    FROM Loan L
    JOIN Client C ON L.ClientID = C.ClientID
    JOIN ProductMaster P ON L.ProductID = P.ProductID
    JOIN Employee E ON L.EmployeeID = E.EmployeeID;
END;
-----------------------------------------------------Account

CREATE PROCEDURE AddAccount 
    @ClientID INT = NULL,
    @AccountNumber VARCHAR(20),
    @ProductID INT,
    @EmployeeID INT,
    @Balance DECIMAL(15,2),
    @OpenDate DATETIME,
    @Status VARCHAR(50)
AS
BEGIN
    
    IF EXISTS (SELECT 1 FROM Account WHERE AccountNumber = @AccountNumber)
    BEGIN
        PRINT 'Account number already exists.';
        RETURN;
    END

   
    INSERT INTO Account (ClientID, AccountNumber, ProductID, EmployeeID, Balance, OpenDate, Status)
    VALUES (@ClientID, @AccountNumber, @ProductID, @EmployeeID, @Balance, @OpenDate, @Status);

    PRINT 'Account added successfully.';
END;
GO


CREATE PROCEDURE UpdateAccount 
    @AccountID INT,
    @Balance DECIMAL(15,2) = NULL,
    @Status VARCHAR(50) = NULL
AS
BEGIN
   
    IF NOT EXISTS (SELECT 1 FROM Account WHERE AccountID = @AccountID)
    BEGIN
        PRINT 'Account not found.';
        RETURN;
    END


    UPDATE Account 
    SET Balance = ISNULL(@Balance, Balance),
        Status = ISNULL(@Status, Status)
    WHERE AccountID = @AccountID;

    PRINT 'Account updated successfully.';
END;
GO

CREATE PROCEDURE DeleteAccount 
    @AccountID INT
AS
BEGIN

    IF EXISTS (SELECT 1 FROM Account WHERE AccountID = @AccountID AND ClientID IS NOT NULL)
    BEGIN
        PRINT 'Cannot delete account because it is linked to a client.';
        RETURN;
    END

 
    DELETE FROM Account WHERE AccountID = @AccountID;
    PRINT 'Account deleted successfully.';
END;
GO


CREATE PROCEDURE GetAccountDetails 
    @AccountID INT = NULL
AS
BEGIN
   
    SELECT 
        A.AccountID,
        A.AccountNumber,
        A.Balance,
        A.Status,
        C.Name AS ClientName,
        P.ProductName,
        E.Name AS EmployeeName
    FROM Account A
    LEFT JOIN Client C ON A.ClientID = C.ClientID
    LEFT JOIN ProductMaster P ON A.ProductID = P.ProductID
    LEFT JOIN Employee E ON A.EmployeeID = E.EmployeeID
    WHERE (@AccountID IS NULL OR A.AccountID = @AccountID);
END;
GO
----------------------------------------Wallet
-- ✅ 1. Insert a new Wallet
CREATE PROCEDURE InsertWallet
    @ClientID INT,
    @ProductID INT,
    @EmployeeID INT,
    @Phone VARCHAR(20),
    @Balance DECIMAL(15,2),
    @ActivationDate DATETIME,
    @Status VARCHAR(15)
AS
BEGIN
    INSERT INTO Wallet (ClientID, ProductID, EmployeeID, Phone, Balance, ActivationDate, Status)
    VALUES (@ClientID, @ProductID, @EmployeeID, @Phone, @Balance, @ActivationDate, @Status);
    
    PRINT '✅ Wallet has been added successfully.'
END;

CREATE PROCEDURE GetWalletByID
    @WalletID INT
AS
BEGIN
    SELECT * FROM Wallet WHERE WalletID = @WalletID;
END;

CREATE PROCEDURE UpdateWallet
    @WalletID INT,
    @Phone VARCHAR(20),
    @Balance DECIMAL(15,2),
    @Status VARCHAR(15)
AS
BEGIN
    UPDATE Wallet
    SET Phone = @Phone, Balance = @Balance, Status = @Status
    WHERE WalletID = @WalletID;

    PRINT '✅ Wallet details have been updated successfully.'
END;

CREATE PROCEDURE DeleteWallet
    @WalletID INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Wallet WHERE WalletID = @WalletID AND ClientID IS NOT NULL)
    BEGIN
        PRINT '❌ Cannot delete the wallet as it is linked to a client.'
        RETURN
    END

    -- Delete the Wallet if not linked to a Client
    DELETE FROM Wallet WHERE WalletID = @WalletID;
    
    PRINT '✅ Wallet has been deleted successfully.'
END;
--------------------------------------
CREATE PROCEDURE AddCard
    @ClientID INT,
    @ProductID INT,
    @EmployeeID INT,
    @CardNumber VARCHAR(20),
    @ExpiryDate DATETIME,
    @CVV INT,
    @Status VARCHAR(15)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Card WHERE CardNumber = @CardNumber)
    BEGIN
        PRINT 'Error: Card number already exists.';
        RETURN;
    END
    
    INSERT INTO Card (ClientID, ProductID, EmployeeID, CardNumber, ExpiryDate, CVV, Status)
    VALUES (@ClientID, @ProductID, @EmployeeID, @CardNumber, @ExpiryDate, @CVV, @Status);
    PRINT 'Success: Card added successfully.';
END;

CREATE PROCEDURE UpdateCard
    @CardID INT,
    @Status VARCHAR(15)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Card WHERE CardID = @CardID)
    BEGIN
        PRINT 'Error: Card not found.';
        RETURN;
    END
    
    UPDATE Card
    SET Status = @Status
    WHERE CardID = @CardID;
    PRINT 'Success: Card updated successfully.';
END;

CREATE PROCEDURE DeleteCard
    @CardID INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Transactions WHERE CardID = @CardID)
    BEGIN
        PRINT 'Error: Cannot delete card as it is linked to transactions.';
        RETURN;
    END
    
    DELETE FROM Card WHERE CardID = @CardID;
    PRINT 'Success: Card deleted successfully.';
END;

CREATE PROCEDURE GetCardDetails
    @CardID INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Card WHERE CardID = @CardID)
    BEGIN
        PRINT 'Error: Card not found.';
        RETURN;
    END
    
    SELECT * FROM Card WHERE CardID = @CardID;
END;

-----------------------------------------------------------------------Certificate
-- Add Certificate
CREATE PROCEDURE AddCertificate
    @ClientID INT,
    @ProductID INT,
    @EmployeeID INT,
    @Amount DECIMAL(15,2),
    @InterestRate DECIMAL(5,2),
    @PayoutInterst INT,
    @IssueDate DATETIME,
    @MaturityDate DATETIME,
    @Status VARCHAR(15)
AS
BEGIN
    INSERT INTO Certificate (ClientID, ProductID, EmployeeID, Amount, InterestRate, PayoutInterst, IssueDate, MaturityDate, Status)
    VALUES (@ClientID, @ProductID, @EmployeeID, @Amount, @InterestRate, @PayoutInterst, @IssueDate, @MaturityDate, @Status);
    PRINT 'Certificate has been successfully added.';
END;

-- Update Certificate
CREATE PROCEDURE UpdateCertificate
    @CertificateID INT,
    @Amount DECIMAL(15,2),
    @InterestRate DECIMAL(5,2),
    @PayoutInterst INT,
    @MaturityDate DATETIME,
    @Status VARCHAR(15)
AS
BEGIN
    UPDATE Certificate
    SET Amount = @Amount, InterestRate = @InterestRate, PayoutInterst = @PayoutInterst, MaturityDate = @MaturityDate, Status = @Status
    WHERE CertificateID = @CertificateID;
    PRINT 'Certificate details have been successfully updated.';
END;

-- Delete Certificate (Ensures it is not linked to a client)
CREATE PROCEDURE DeleteCertificate
    @CertificateID INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Certificate WHERE CertificateID = @CertificateID)
    BEGIN
        DELETE FROM Certificate WHERE CertificateID = @CertificateID;
        PRINT 'Certificate has been successfully deleted.';
    END
    ELSE
    BEGIN
        PRINT 'Certificate deletion failed: It is linked to a client.';
    END
END;

-- Get Certificate Details
CREATE PROCEDURE GetCertificateDetails
    @CertificateID INT
AS
BEGIN
    SELECT * FROM Certificate WHERE CertificateID = @CertificateID;
    PRINT 'Certificate details retrieved successfully.';
END;
-----------------------------------------------------------------OnlineBanking
-- Insert Procedure
CREATE PROCEDURE InsertOnlineBanking
    @ClientID INT,
    @ProductID INT,
    @EmployeeID INT,
    @SubscriptionDate DATE,
    @Status VARCHAR(15)
AS
BEGIN
    INSERT INTO OnlineBanking (ClientID, ProductID, EmployeeID, SubscriptionDate, Status)
    VALUES (@ClientID, @ProductID, @EmployeeID, @SubscriptionDate, @Status);
    PRINT 'Online Banking record inserted successfully.';
END;

-- Update Procedure
CREATE PROCEDURE UpdateOnlineBanking
    @OnlineBankingID INT,
    @Status VARCHAR(15)
AS
BEGIN
    UPDATE OnlineBanking
    SET Status = @Status
    WHERE OnlineBankingID = @OnlineBankingID;
    PRINT 'Online Banking record updated successfully.';
END;

-- Delete Procedure
CREATE PROCEDURE DeleteOnlineBanking
    @OnlineBankingID INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Transactions WHERE OnlineBankingID = @OnlineBankingID)
    BEGIN
        PRINT 'Error: Cannot delete Online Banking record as it is linked to transactions.';
        RETURN;
    END;
    DELETE FROM OnlineBanking WHERE OnlineBankingID = @OnlineBankingID;
    PRINT 'Online Banking record deleted successfully.';
END;

-- Select Procedure
CREATE PROCEDURE GetOnlineBanking
AS
BEGIN
    SELECT * FROM OnlineBanking;
END;
---------------------------------------------------------------------------------------------
-- Insert Procedure
CREATE PROCEDURE InsertATM
    @ATMNum INT,
    @BranchName VARCHAR(100),
    @CashCapacity INT,
    @InstallationDate DATE,
    @LastMaintenance DATE,
    @Status VARCHAR(15)
AS
BEGIN
    DECLARE @BranchID INT;
    SELECT @BranchID = BranchID FROM Branch WHERE BranchName = @BranchName;
    
    IF @BranchID IS NULL
    BEGIN
        PRINT 'Error: Branch not found.';
        RETURN;
    END;
    
    INSERT INTO ATM (ATMNum, BranchID, CashCapacity, InstallationDate, LastMaintenance, Status)
    VALUES (@ATMNum, @BranchID, @CashCapacity, @InstallationDate, @LastMaintenance, @Status);
    PRINT 'ATM record inserted successfully.';
END;

-- Update Procedure
CREATE PROCEDURE UpdateATM
    @ATMID INT,
    @Status VARCHAR(15),
    @LastMaintenance DATE
AS
BEGIN
    UPDATE ATM
    SET Status = @Status, LastMaintenance = @LastMaintenance
    WHERE ATMID = @ATMID;
    PRINT 'ATM record updated successfully.';
END;

-- Delete Procedure
CREATE PROCEDURE DeleteATM
    @ATMID INT
AS
BEGIN
    DECLARE @Status VARCHAR(15);

    SELECT @Status = Status FROM ATM WHERE ATMID = @ATMID;
    
   
    IF @Status IS NULL
    BEGIN
        PRINT 'Error: ATM record not found.';
        RETURN;
    END

    IF @Status = 'Inactive'
    BEGIN
        PRINT 'Error: Cannot delete an Inactive ATM record.';
        RETURN;
    END
    IF EXISTS (SELECT 1 FROM Transactions WHERE ATMID = @ATMID)
    BEGIN
        PRINT 'Error: Cannot delete ATM record as it is linked to transactions.';
        RETURN;
    END;

    
    DELETE FROM ATM WHERE ATMID = @ATMID;
    PRINT 'ATM record deleted successfully.';
END;

-- Select Procedure
CREATE PROCEDURE GetATM
AS
BEGIN
    SELECT * FROM ATM;
END;
--------------------------------------------------------------Expense
-- Insert Procedure
CREATE PROCEDURE InsertExpense
    @ExpenseType VARCHAR(255),
    @Amount DECIMAL(15,2),
    @BranchName VARCHAR(255), 
    @ExpenseDate DATETIME,
    @InvoiceNum VARCHAR(60),
    @Vendor VARCHAR(100),
    @Status VARCHAR(15)
AS
BEGIN
    DECLARE @BranchID INT;
    SELECT @BranchID = BranchID FROM Branch WHERE BranchName = @BranchName;
    
    IF @BranchID IS NULL
    BEGIN
        PRINT 'Error: Branch not found.';
        RETURN;
    END

    INSERT INTO Expenses (ExpenseType, Amount, BranchID, ExpenseDate, InvoiceNum, Vendor, Status)
    VALUES (@ExpenseType, @Amount, @BranchID, @ExpenseDate, @InvoiceNum, @Vendor, @Status);
    
    PRINT 'Expense record inserted successfully.';
END;

-- Update Procedure
CREATE PROCEDURE UpdateExpense
    @BranchName VARCHAR(255),
    @ExpenseType VARCHAR(255),
    @Amount DECIMAL(15,2),
    @ExpenseDate DATETIME,
    @Status VARCHAR(15)
AS
BEGIN
    DECLARE @BranchID INT, @ExpenseID INT;
   
    SELECT @BranchID = BranchID FROM Branch WHERE BranchName = @BranchName;
    
    IF @BranchID IS NULL
    BEGIN
        PRINT 'Error: Branch not found.';
        RETURN;
    END
    
    SELECT @ExpenseID = ExpenseID FROM Expenses WHERE BranchID = @BranchID AND ExpenseType = @ExpenseType;
    
    IF @ExpenseID IS NULL
    BEGIN
        PRINT 'Error: Expense record not found for this branch.';
        RETURN;
    END

    
    UPDATE Expenses
    SET Amount = @Amount, ExpenseDate = @ExpenseDate, Status =


    INSERT INTO Expenses (ExpenseType, Amount, BranchID, ExpenseDate, InvoiceNum, Vendor)
    VALUES (@ExpenseType, @Amount, @BranchID, @ExpenseDate, @InvoiceNum, @Vendor);
    
    PRINT 'Expense record inserted successfully.';
END;

-- Update Procedure
CREATE PROCEDURE UpdateExpense
    @ExpenseID INT,
    @Amount DECIMAL(15,2),
    @ExpenseDate DATETIME
AS
BEGIN
    UPDATE Expenses
    SET Amount = @Amount, ExpenseDate = @ExpenseDate
    WHERE ExpenseID = @ExpenseID;
    
    PRINT 'Expense record updated successfully.';
END;

-- Delete Procedure
CREATE PROCEDURE DeleteExpense
    @ExpenseID INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Transactions WHERE ExpenseID = @ExpenseID)
    BEGIN
        PRINT 'Error: Cannot delete Expense record as it is linked to transactions.';
        RETURN;
    END;
    
    DELETE FROM Expenses WHERE ExpenseID = @ExpenseID;
    PRINT 'Expense record deleted successfully.';
END;

-- Select Procedure
CREATE PROCEDURE GetExpenses
AS
BEGIN
    SELECT * FROM Expenses;
END;
