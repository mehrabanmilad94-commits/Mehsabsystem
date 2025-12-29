-- =============================================
-- نرم‌افزار حسابداری جامع MEHSAB
-- Entity Relationship Diagram (ERD) 
-- SQL Server Script
-- =============================================

-- ==============================
-- 1. جداول اصلی سیستم (System)
-- ==============================

-- تنظیمات سیستم
CREATE TABLE SystemSettings (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    CompanyName NVARCHAR(200) NOT NULL,
    CompanyCode NVARCHAR(50),
    TaxId NVARCHAR(50),
    Address NVARCHAR(500),
    Phone NVARCHAR(50),
    Email NVARCHAR(100),
    LogoPath NVARCHAR(500),
    FiscalYearStart DATE NOT NULL,
    FiscalYearEnd DATE NOT NULL,
    BaseCurrency NVARCHAR(10) DEFAULT 'IRR',
    DecimalPlaces INT DEFAULT 0,
    DateFormat NVARCHAR(20) DEFAULT 'yyyy/MM/dd',
    IsVATEnabled BIT DEFAULT 1,
    DefaultVATRate DECIMAL(5,2) DEFAULT 9.00,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    IsDeleted BIT DEFAULT 0
);

-- مراکز هزینه
CREATE TABLE CostCenters (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Code NVARCHAR(20) NOT NULL UNIQUE,
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(500),
    ParentId INT NULL,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT,
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedBy INT,
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (ParentId) REFERENCES CostCenters(Id)
);

-- ==============================
-- 2. مدیریت کاربران و امنیت
-- ==============================

CREATE TABLE Users (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(256) NOT NULL,
    Salt NVARCHAR(256) NOT NULL,
    FullName NVARCHAR(200) NOT NULL,
    Email NVARCHAR(100),
    Phone NVARCHAR(50),
    IsActive BIT DEFAULT 1,
    LastLoginDate DATETIME2,
    FailedLoginAttempts INT DEFAULT 0,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    IsDeleted BIT DEFAULT 0
);

CREATE TABLE Roles (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(500),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    IsDeleted BIT DEFAULT 0
);

CREATE TABLE UserRoles (
    UserId INT,
    RoleId INT,
    AssignedAt DATETIME2 DEFAULT GETDATE(),
    AssignedBy INT,
    PRIMARY KEY (UserId, RoleId),
    FOREIGN KEY (UserId) REFERENCES Users(Id),
    FOREIGN KEY (RoleId) REFERENCES Roles(Id)
);

-- لاگ فعالیت‌ها (Audit Trail)
CREATE TABLE AuditLogs (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    EntityName NVARCHAR(100) NOT NULL,
    EntityId INT,
    Action NVARCHAR(50) NOT NULL, -- INSERT, UPDATE, DELETE
    OldValues NVARCHAR(MAX),
    NewValues NVARCHAR(MAX),
    TimeStamp DATETIME2 DEFAULT GETDATE(),
    IPAddress NVARCHAR(45),
    UserAgent NVARCHAR(500),
    FOREIGN KEY (UserId) REFERENCES Users(Id)
);

-- ==============================
-- 3. ماژول حسابداری (کدینگ 5 سطحی)
-- ==============================

CREATE TABLE AccountGroups (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Code NVARCHAR(20) NOT NULL UNIQUE, -- کد گروه
    Name NVARCHAR(200) NOT NULL,
    Level INT NOT NULL, -- 1 تا 5
    ParentId INT NULL,
    Nature NVARCHAR(10) NOT NULL, -- Debit, Credit
    AccountType NVARCHAR(20) NOT NULL, -- Assets, Liabilities, Equity, Revenue, Expense
    IsSystemAccount BIT DEFAULT 0, -- حساب‌های سیستمی
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT,
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedBy INT,
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (ParentId) REFERENCES AccountGroups(Id),
    FOREIGN KEY (CreatedBy) REFERENCES Users(Id),
    FOREIGN KEY (ModifiedBy) REFERENCES Users(Id)
);

-- اسناد حسابداری
CREATE TABLE Vouchers (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    VoucherNumber NVARCHAR(50) NOT NULL,
    VoucherDate DATE NOT NULL,
    Description NVARCHAR(1000),
    Reference NVARCHAR(100), -- مرجع (فاکتور، چک و غیره)
    TotalDebitAmount DECIMAL(18,0) NOT NULL DEFAULT 0,
    TotalCreditAmount DECIMAL(18,0) NOT NULL DEFAULT 0,
    VoucherType NVARCHAR(50) DEFAULT 'Manual', -- Manual, Auto_Sale, Auto_Purchase, etc.
    Status NVARCHAR(20) DEFAULT 'Draft', -- Draft, Posted, Reversed
    CostCenterId INT,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NOT NULL,
    PostedAt DATETIME2,
    PostedBy INT,
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedBy INT,
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (CostCenterId) REFERENCES CostCenters(Id),
    FOREIGN KEY (CreatedBy) REFERENCES Users(Id),
    FOREIGN KEY (PostedBy) REFERENCES Users(Id),
    FOREIGN KEY (ModifiedBy) REFERENCES Users(Id)
);

-- آیتم‌های سند
CREATE TABLE VoucherItems (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    VoucherId INT NOT NULL,
    AccountId INT NOT NULL,
    Description NVARCHAR(500),
    DebitAmount DECIMAL(18,0) DEFAULT 0,
    CreditAmount DECIMAL(18,0) DEFAULT 0,
    CostCenterId INT,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (VoucherId) REFERENCES Vouchers(Id) ON DELETE CASCADE,
    FOREIGN KEY (AccountId) REFERENCES AccountGroups(Id),
    FOREIGN KEY (CostCenterId) REFERENCES CostCenters(Id)
);

-- ==============================
-- 4. ماژول مشتریان و تأمین‌کنندگان
-- ==============================

CREATE TABLE Customers (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Code NVARCHAR(50) NOT NULL UNIQUE,
    Name NVARCHAR(200) NOT NULL,
    ContactPerson NVARCHAR(100),
    Phone NVARCHAR(50),
    Mobile NVARCHAR(50),
    Email NVARCHAR(100),
    Website NVARCHAR(200),
    Address NVARCHAR(1000),
    City NVARCHAR(100),
    Province NVARCHAR(100),
    PostalCode NVARCHAR(20),
    TaxId NVARCHAR(50), -- شناسه مالیاتی
    EconomicCode NVARCHAR(50), -- کد اقتصادی
    CreditLimit DECIMAL(18,0) DEFAULT 0,
    PaymentTermDays INT DEFAULT 0, -- مهلت پرداخت
    AccountId INT, -- حساب تفصیلی
    IsActive BIT DEFAULT 1,
    CustomerType NVARCHAR(50) DEFAULT 'Individual', -- Individual, Company
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT,
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedBy INT,
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (AccountId) REFERENCES AccountGroups(Id),
    FOREIGN KEY (CreatedBy) REFERENCES Users(Id),
    FOREIGN KEY (ModifiedBy) REFERENCES Users(Id)
);

CREATE TABLE Suppliers (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Code NVARCHAR(50) NOT NULL UNIQUE,
    Name NVARCHAR(200) NOT NULL,
    ContactPerson NVARCHAR(100),
    Phone NVARCHAR(50),
    Mobile NVARCHAR(50),
    Email NVARCHAR(100),
    Website NVARCHAR(200),
    Address NVARCHAR(1000),
    City NVARCHAR(100),
    Province NVARCHAR(100),
    PostalCode NVARCHAR(20),
    TaxId NVARCHAR(50),
    EconomicCode NVARCHAR(50),
    PaymentTermDays INT DEFAULT 30,
    AccountId INT, -- حساب تفصیلی
    IsActive BIT DEFAULT 1,
    SupplierType NVARCHAR(50) DEFAULT 'Company',
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT,
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedBy INT,
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (AccountId) REFERENCES AccountGroups(Id),
    FOREIGN KEY (CreatedBy) REFERENCES Users(Id),
    FOREIGN KEY (ModifiedBy) REFERENCES Users(Id)
);

-- ==============================
-- 5. ماژول انبارداری
-- ==============================

CREATE TABLE ProductCategories (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Code NVARCHAR(50) NOT NULL UNIQUE,
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(500),
    ParentId INT,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT,
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedBy INT,
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (ParentId) REFERENCES ProductCategories(Id),
    FOREIGN KEY (CreatedBy) REFERENCES Users(Id),
    FOREIGN KEY (ModifiedBy) REFERENCES Users(Id)
);

CREATE TABLE Units (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Code NVARCHAR(20) NOT NULL UNIQUE,
    Name NVARCHAR(100) NOT NULL,
    IsBaseUnit BIT DEFAULT 0,
    ConversionFactor DECIMAL(10,4) DEFAULT 1, -- ضریب تبدیل
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    IsDeleted BIT DEFAULT 0
);

CREATE TABLE Products (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Code NVARCHAR(50) NOT NULL UNIQUE,
    Barcode NVARCHAR(50),
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(1000),
    CategoryId INT,
    UnitId INT NOT NULL,
    PurchasePrice DECIMAL(18,0) DEFAULT 0,
    SalePrice DECIMAL(18,0) DEFAULT 0,
    MinimumStock DECIMAL(10,2) DEFAULT 0,
    MaximumStock DECIMAL(10,2) DEFAULT 0,
    ReorderLevel DECIMAL(10,2) DEFAULT 0,
    IsVATApplicable BIT DEFAULT 1,
    VATRate DECIMAL(5,2) DEFAULT 9.00,
    ProductType NVARCHAR(50) DEFAULT 'Goods', -- Goods, Service, Raw Material
    CostingMethod NVARCHAR(20) DEFAULT 'FIFO', -- FIFO, WeightedAverage
    PurchaseAccountId INT, -- حساب خرید
    SaleAccountId INT, -- حساب فروش
    InventoryAccountId INT, -- حساب موجودی
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT,
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedBy INT,
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (CategoryId) REFERENCES ProductCategories(Id),
    FOREIGN KEY (UnitId) REFERENCES Units(Id),
    FOREIGN KEY (PurchaseAccountId) REFERENCES AccountGroups(Id),
    FOREIGN KEY (SaleAccountId) REFERENCES AccountGroups(Id),
    FOREIGN KEY (InventoryAccountId) REFERENCES AccountGroups(Id),
    FOREIGN KEY (CreatedBy) REFERENCES Users(Id),
    FOREIGN KEY (ModifiedBy) REFERENCES Users(Id)
);

CREATE TABLE Warehouses (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Code NVARCHAR(50) NOT NULL UNIQUE,
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(500),
    Address NVARCHAR(1000),
    WarehouseKeeper NVARCHAR(100),
    Phone NVARCHAR(50),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT,
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedBy INT,
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (CreatedBy) REFERENCES Users(Id),
    FOREIGN KEY (ModifiedBy) REFERENCES Users(Id)
);

-- موجودی انبار
CREATE TABLE WarehouseInventory (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    ProductId INT NOT NULL,
    WarehouseId INT NOT NULL,
    Quantity DECIMAL(10,2) NOT NULL DEFAULT 0,
    UnitCost DECIMAL(18,0) DEFAULT 0,
    TotalValue DECIMAL(18,0) DEFAULT 0,
    LastUpdated DATETIME2 DEFAULT GETDATE(),
    UNIQUE(ProductId, WarehouseId),
    FOREIGN KEY (ProductId) REFERENCES Products(Id),
    FOREIGN KEY (WarehouseId) REFERENCES Warehouses(Id)
);

-- حرکات انبار
CREATE TABLE InventoryTransactions (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    TransactionDate DATE NOT NULL,
    TransactionNumber NVARCHAR(50) NOT NULL,
    TransactionType NVARCHAR(50) NOT NULL, -- Receipt, Issue, Transfer, Adjustment
    ProductId INT NOT NULL,
    WarehouseId INT NOT NULL,
    Quantity DECIMAL(10,2) NOT NULL,
    UnitCost DECIMAL(18,0) DEFAULT 0,
    TotalAmount DECIMAL(18,0) DEFAULT 0,
    Description NVARCHAR(500),
    ReferenceType NVARCHAR(50), -- Invoice, Voucher, etc.
    ReferenceId INT,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NOT NULL,
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (ProductId) REFERENCES Products(Id),
    FOREIGN KEY (WarehouseId) REFERENCES Warehouses(Id),
    FOREIGN KEY (CreatedBy) REFERENCES Users(Id)
);

-- ==============================
-- 6. ماژول فروش
-- ==============================

CREATE TABLE SalesInvoices (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceNumber NVARCHAR(50) NOT NULL UNIQUE,
    InvoiceDate DATE NOT NULL,
    CustomerId INT NOT NULL,
    InvoiceType NVARCHAR(50) DEFAULT 'Sale', -- Sale, Return, ProForma
    PaymentType NVARCHAR(20) DEFAULT 'Credit', -- Cash, Credit, Mixed
    SubTotal DECIMAL(18,0) NOT NULL DEFAULT 0,
    DiscountAmount DECIMAL(18,0) DEFAULT 0,
    VATAmount DECIMAL(18,0) DEFAULT 0,
    TotalAmount DECIMAL(18,0) NOT NULL DEFAULT 0,
    PaidAmount DECIMAL(18,0) DEFAULT 0,
    RemainAmount DECIMAL(18,0) DEFAULT 0,
    Description NVARCHAR(1000),
    Status NVARCHAR(20) DEFAULT 'Draft', -- Draft, Posted, Cancelled
    SalespersonId INT,
    WarehouseId INT,
    -- سامانه مودیان
    TaxApiId NVARCHAR(100), -- شناسه یکتای مالیاتی
    TaxApiStatus NVARCHAR(50) DEFAULT 'NotSent', -- NotSent, Sent, Confirmed, Rejected
    TaxApiResponse NVARCHAR(MAX),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NOT NULL,
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedBy INT,
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (CustomerId) REFERENCES Customers(Id),
    FOREIGN KEY (SalespersonId) REFERENCES Users(Id),
    FOREIGN KEY (WarehouseId) REFERENCES Warehouses(Id),
    FOREIGN KEY (CreatedBy) REFERENCES Users(Id),
    FOREIGN KEY (ModifiedBy) REFERENCES Users(Id)
);

CREATE TABLE SalesInvoiceItems (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity DECIMAL(10,2) NOT NULL,
    UnitPrice DECIMAL(18,0) NOT NULL,
    DiscountPercent DECIMAL(5,2) DEFAULT 0,
    DiscountAmount DECIMAL(18,0) DEFAULT 0,
    VATRate DECIMAL(5,2) DEFAULT 9.00,
    VATAmount DECIMAL(18,0) DEFAULT 0,
    TotalAmount DECIMAL(18,0) NOT NULL,
    Description NVARCHAR(500),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (InvoiceId) REFERENCES SalesInvoices(Id) ON DELETE CASCADE,
    FOREIGN KEY (ProductId) REFERENCES Products(Id)
);

-- ==============================
-- 7. ماژول خرید
-- ==============================

CREATE TABLE PurchaseInvoices (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceNumber NVARCHAR(50) NOT NULL UNIQUE,
    InvoiceDate DATE NOT NULL,
    SupplierId INT NOT NULL,
    InvoiceType NVARCHAR(50) DEFAULT 'Purchase', -- Purchase, Return
    PaymentType NVARCHAR(20) DEFAULT 'Credit',
    SubTotal DECIMAL(18,0) NOT NULL DEFAULT 0,
    DiscountAmount DECIMAL(18,0) DEFAULT 0,
    VATAmount DECIMAL(18,0) DEFAULT 0,
    TotalAmount DECIMAL(18,0) NOT NULL DEFAULT 0,
    PaidAmount DECIMAL(18,0) DEFAULT 0,
    RemainAmount DECIMAL(18,0) DEFAULT 0,
    Description NVARCHAR(1000),
    Status NVARCHAR(20) DEFAULT 'Draft',
    WarehouseId INT,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NOT NULL,
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedBy INT,
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (SupplierId) REFERENCES Suppliers(Id),
    FOREIGN KEY (WarehouseId) REFERENCES Warehouses(Id),
    FOREIGN KEY (CreatedBy) REFERENCES Users(Id),
    FOREIGN KEY (ModifiedBy) REFERENCES Users(Id)
);

CREATE TABLE PurchaseInvoiceItems (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceId INT NOT NULL,
    ProductId INT NOT NULL,
    Quantity DECIMAL(10,2) NOT NULL,
    UnitPrice DECIMAL(18,0) NOT NULL,
    DiscountPercent DECIMAL(5,2) DEFAULT 0,
    DiscountAmount DECIMAL(18,0) DEFAULT 0,
    VATRate DECIMAL(5,2) DEFAULT 9.00,
    VATAmount DECIMAL(18,0) DEFAULT 0,
    TotalAmount DECIMAL(18,0) NOT NULL,
    Description NVARCHAR(500),
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (InvoiceId) REFERENCES PurchaseInvoices(Id) ON DELETE CASCADE,
    FOREIGN KEY (ProductId) REFERENCES Products(Id)
);

-- ==============================
-- 8. ماژول خزانه‌داری
-- ==============================

-- صندوق‌ها
CREATE TABLE CashBoxes (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Code NVARCHAR(50) NOT NULL UNIQUE,
    Name NVARCHAR(200) NOT NULL,
    Description NVARCHAR(500),
    Balance DECIMAL(18,0) DEFAULT 0,
    AccountId INT, -- حساب تفصیلی
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT,
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedBy INT,
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (AccountId) REFERENCES AccountGroups(Id),
    FOREIGN KEY (CreatedBy) REFERENCES Users(Id),
    FOREIGN KEY (ModifiedBy) REFERENCES Users(Id)
);

-- حساب‌های بانکی
CREATE TABLE BankAccounts (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    BankName NVARCHAR(100) NOT NULL,
    BranchName NVARCHAR(100),
    AccountNumber NVARCHAR(50) NOT NULL,
    AccountTitle NVARCHAR(200) NOT NULL,
    IBAN NVARCHAR(50),
    ShabaNumber NVARCHAR(50),
    Balance DECIMAL(18,0) DEFAULT 0,
    AccountId INT, -- حساب تفصیلی
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT,
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedBy INT,
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (AccountId) REFERENCES AccountGroups(Id),
    FOREIGN KEY (CreatedBy) REFERENCES Users(Id),
    FOREIGN KEY (ModifiedBy) REFERENCES Users(Id)
);

-- چک‌ها
CREATE TABLE Cheques (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    ChequeNumber NVARCHAR(50) NOT NULL,
    ChequeDate DATE NOT NULL,
    DueDate DATE NOT NULL,
    Amount DECIMAL(18,0) NOT NULL,
    ChequeType NVARCHAR(20) NOT NULL, -- Receivable, Payable
    Status NVARCHAR(20) DEFAULT 'Received', -- Received, Deposited, Cashed, Returned, Cancelled
    BankName NVARCHAR(100) NOT NULL,
    BranchName NVARCHAR(100),
    AccountNumber NVARCHAR(50),
    DrawerName NVARCHAR(200), -- کشنده
    PayeeName NVARCHAR(200), -- ذینفع
    Description NVARCHAR(500),
    CustomerId INT, -- برای چک‌های دریافتی
    SupplierId INT, -- برای چک‌های پرداختی
    BankAccountId INT, -- حساب بانکی مربوطه
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NOT NULL,
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedBy INT,
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (CustomerId) REFERENCES Customers(Id),
    FOREIGN KEY (SupplierId) REFERENCES Suppliers(Id),
    FOREIGN KEY (BankAccountId) REFERENCES BankAccounts(Id),
    FOREIGN KEY (CreatedBy) REFERENCES Users(Id),
    FOREIGN KEY (ModifiedBy) REFERENCES Users(Id)
);

-- ==============================
-- 9. ماژول حقوق و دستمزد  
-- ==============================

CREATE TABLE Employees (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeNumber NVARCHAR(50) NOT NULL UNIQUE,
    NationalId NVARCHAR(20) NOT NULL UNIQUE,
    FirstName NVARCHAR(100) NOT NULL,
    LastName NVARCHAR(100) NOT NULL,
    FatherName NVARCHAR(100),
    BirthDate DATE,
    Gender NVARCHAR(10),
    MaritalStatus NVARCHAR(20),
    Phone NVARCHAR(50),
    Mobile NVARCHAR(50),
    Email NVARCHAR(100),
    Address NVARCHAR(1000),
    HireDate DATE NOT NULL,
    JobTitle NVARCHAR(100),
    Department NVARCHAR(100),
    BasicSalary DECIMAL(18,0) DEFAULT 0,
    IsActive BIT DEFAULT 1,
    -- اطلاعات بیمه
    InsuranceNumber NVARCHAR(50),
    InsuranceStartDate DATE,
    -- اطلاعات حساب بانکی
    BankAccountNumber NVARCHAR(50),
    BankName NVARCHAR(100),
    AccountId INT, -- حساب تفصیلی
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT,
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedBy INT,
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (AccountId) REFERENCES AccountGroups(Id),
    FOREIGN KEY (CreatedBy) REFERENCES Users(Id),
    FOREIGN KEY (ModifiedBy) REFERENCES Users(Id)
);

-- ==============================
-- 10. ماژول تولید
-- ==============================

-- فهرست مواد (BOM)
CREATE TABLE BillOfMaterials (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    ProductId INT NOT NULL, -- محصول نهایی
    ComponentProductId INT NOT NULL, -- جزء (مواد اولیه)
    Quantity DECIMAL(10,4) NOT NULL, -- مقدار مورد نیاز
    UnitCost DECIMAL(18,0) DEFAULT 0,
    Sequence INT DEFAULT 1,
    Description NVARCHAR(500),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT,
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedBy INT,
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (ProductId) REFERENCES Products(Id),
    FOREIGN KEY (ComponentProductId) REFERENCES Products(Id),
    FOREIGN KEY (CreatedBy) REFERENCES Users(Id),
    FOREIGN KEY (ModifiedBy) REFERENCES Users(Id)
);

-- دستورات تولید
CREATE TABLE ProductionOrders (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    OrderNumber NVARCHAR(50) NOT NULL UNIQUE,
    OrderDate DATE NOT NULL,
    ProductId INT NOT NULL,
    PlannedQuantity DECIMAL(10,2) NOT NULL,
    ProducedQuantity DECIMAL(10,2) DEFAULT 0,
    Status NVARCHAR(20) DEFAULT 'Planned', -- Planned, InProgress, Completed, Cancelled
    PlannedStartDate DATE,
    PlannedEndDate DATE,
    ActualStartDate DATE,
    ActualEndDate DATE,
    WarehouseId INT,
    Description NVARCHAR(1000),
    TotalMaterialCost DECIMAL(18,0) DEFAULT 0,
    TotalLaborCost DECIMAL(18,0) DEFAULT 0,
    TotalOverheadCost DECIMAL(18,0) DEFAULT 0,
    TotalCost DECIMAL(18,0) DEFAULT 0,
    CreatedAt DATETIME2 DEFAULT GETDATE(),
    CreatedBy INT NOT NULL,
    ModifiedAt DATETIME2 DEFAULT GETDATE(),
    ModifiedBy INT,
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY (ProductId) REFERENCES Products(Id),
    FOREIGN KEY (WarehouseId) REFERENCES Warehouses(Id),
    FOREIGN KEY (CreatedBy) REFERENCES Users(Id),
    FOREIGN KEY (ModifiedBy) REFERENCES Users(Id)
);

-- ==============================
-- 11. ایندکس‌ها (Indexes)
-- ==============================

-- ایندکس‌های اصلی برای کارایی
CREATE INDEX IX_Vouchers_VoucherDate ON Vouchers(VoucherDate);
CREATE INDEX IX_Vouchers_VoucherNumber ON Vouchers(VoucherNumber);
CREATE INDEX IX_VoucherItems_AccountId ON VoucherItems(AccountId);
CREATE INDEX IX_SalesInvoices_InvoiceDate ON SalesInvoices(InvoiceDate);
CREATE INDEX IX_SalesInvoices_CustomerId ON SalesInvoices(CustomerId);
CREATE INDEX IX_PurchaseInvoices_InvoiceDate ON PurchaseInvoices(InvoiceDate);
CREATE INDEX IX_PurchaseInvoices_SupplierId ON PurchaseInvoices(SupplierId);
CREATE INDEX IX_InventoryTransactions_ProductId ON InventoryTransactions(ProductId);
CREATE INDEX IX_InventoryTransactions_WarehouseId ON InventoryTransactions(WarehouseId);
CREATE INDEX IX_InventoryTransactions_TransactionDate ON InventoryTransactions(TransactionDate);

-- ==============================
-- 12. ویوها (Views) 
-- ==============================

-- ویوی کدینگ کامل
CREATE VIEW vw_ChartOfAccounts AS
SELECT 
    ag.Id,
    ag.Code,
    ag.Name,
    ag.Level,
    ag.ParentId,
    ag.Nature,
    ag.AccountType,
    ag.IsActive,
    CASE ag.Level 
        WHEN 1 THEN ag.Name
        WHEN 2 THEN p1.Name + ' / ' + ag.Name
        WHEN 3 THEN p2.Name + ' / ' + p1.Name + ' / ' + ag.Name
        WHEN 4 THEN p3.Name + ' / ' + p2.Name + ' / ' + p1.Name + ' / ' + ag.Name
        WHEN 5 THEN p4.Name + ' / ' + p3.Name + ' / ' + p2.Name + ' / ' + p1.Name + ' / ' + ag.Name
    END as FullName
FROM AccountGroups ag
LEFT JOIN AccountGroups p1 ON ag.ParentId = p1.Id
LEFT JOIN AccountGroups p2 ON p1.ParentId = p2.Id  
LEFT JOIN AccountGroups p3 ON p2.ParentId = p3.Id
LEFT JOIN AccountGroups p4 ON p3.ParentId = p4.Id
WHERE ag.IsDeleted = 0;

-- ویوی تراز آزمایشی
CREATE VIEW vw_TrialBalance AS
SELECT 
    ag.Id,
    ag.Code,
    ag.Name,
    ag.Nature,
    COALESCE(SUM(vi.DebitAmount), 0) as TotalDebit,
    COALESCE(SUM(vi.CreditAmount), 0) as TotalCredit,
    CASE ag.Nature
        WHEN 'Debit' THEN COALESCE(SUM(vi.DebitAmount), 0) - COALESCE(SUM(vi.CreditAmount), 0)
        ELSE COALESCE(SUM(vi.CreditAmount), 0) - COALESCE(SUM(vi.DebitAmount), 0)
    END as Balance
FROM AccountGroups ag
LEFT JOIN VoucherItems vi ON ag.Id = vi.AccountId
LEFT JOIN Vouchers v ON vi.VoucherId = v.Id AND v.Status = 'Posted' AND v.IsDeleted = 0
WHERE ag.IsDeleted = 0 AND ag.Level = 5 -- فقط حساب‌های تفصیلی
GROUP BY ag.Id, ag.Code, ag.Name, ag.Nature;

-- ==============================
-- پایان اسکریپت ERD
-- ==============================