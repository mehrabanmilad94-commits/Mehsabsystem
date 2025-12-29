# MEHSAB Comprehensive Accounting System
# Technical Architecture Documentation

## Version: 1.0.0
## Date: December 23, 2024
## Author: MEHSAB Development Team

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Overview](#architecture-overview)
3. [Technology Stack](#technology-stack)
4. [Database Design](#database-design)
5. [Business Logic](#business-logic)
6. [User Interface](#user-interface)
7. [Security Architecture](#security-architecture)
8. [Integration Points](#integration-points)
9. [Deployment Architecture](#deployment-architecture)
10. [Performance Considerations](#performance-considerations)

---

## System Overview

MEHSAB is a comprehensive accounting and financial management system designed for Persian businesses. The system implements Domain-Driven Design (DDD) principles with a layered architecture to ensure maintainability, scalability, and business rule enforcement.

### Key Features
- 5-Level Chart of Accounts (compatible with Sepidar)
- Rule-Based Automatic Journal Entry Posting
- Complete Inventory Management with FIFO/Average costing
- Sales and Purchase Management with VAT support
- Treasury Management (Cash, Bank, Checks)
- Industrial Production with BOM and Costing
- Persian Payroll with Iranian Tax/Insurance compliance
- Tax Payer System Integration (Samaneh Modian)
- Professional Reporting (Stimulsoft/DevExpress)
- Multi-format Import/Export (Excel, PDF, CSV, Word)

---

## Architecture Overview

### Domain-Driven Design (DDD) Layers

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│        (WPF with MVVM Pattern)          │
├─────────────────────────────────────────┤
│           Application Layer             │
│    (Services, DTOs, Commands/Queries)   │
├─────────────────────────────────────────┤
│             Domain Layer                │
│      (Entities, Value Objects,          │
│    Domain Services, Business Rules)     │
├─────────────────────────────────────────┤
│          Infrastructure Layer           │
│  (Data Access, External Services,       │
│     File System, Email, etc.)          │
└─────────────────────────────────────────┘
```

### Key Architectural Patterns

#### 1. Repository Pattern + Unit of Work
```csharp
public interface IUnitOfWork : IDisposable
{
    IChartOfAccountRepository ChartOfAccounts { get; }
    IJournalEntryRepository JournalEntries { get; }
    IInventoryItemRepository InventoryItems { get; }
    // ... other repositories
    
    Task<int> CommitAsync();
    Task BeginTransactionAsync();
    Task CommitTransactionAsync();
    Task RollbackTransactionAsync();
}
```

#### 2. Rule-Based Posting Engine
```csharp
public class RuleBasedPostingService : IRuleBasedPostingService
{
    public async Task PostInventoryMovementAsync(InventoryMovement movement)
    {
        var rules = await GetPostingRulesAsync("INVENTORY_MOVEMENT");
        var journalEntries = ApplyRules(movement, rules);
        await PostJournalEntriesAsync(journalEntries);
    }
}
```

#### 3. CQRS Pattern (Command Query Responsibility Segregation)
```csharp
public class CreateJournalEntryCommand : IRequest<Guid>
{
    public string DocumentNumber { get; set; }
    public DateTime EntryDate { get; set; }
    public List<JournalEntryLineDto> Lines { get; set; }
}

public class GetTrialBalanceQuery : IRequest<TrialBalanceDto>
{
    public DateTime AsOfDate { get; set; }
    public bool IncludeZeroBalances { get; set; }
}
```

---

## Technology Stack

### Core Technologies
- **Framework**: .NET 8.0
- **UI Framework**: WPF (Windows Presentation Foundation)
- **Architecture Pattern**: MVVM (Model-View-ViewModel)
- **Database**: SQL Server Express LocalDB 2022
- **ORM**: Entity Framework Core 8.0

### Supporting Libraries
```xml
<!-- Core Dependencies -->
<PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="8.0.0" />
<PackageReference Include="Microsoft.Extensions.DependencyInjection" Version="8.0.0" />
<PackageReference Include="AutoMapper" Version="12.0.1" />
<PackageReference Include="FluentValidation" Version="11.8.1" />

<!-- UI Enhancement -->
<PackageReference Include="FontAwesome.WPF" Version="4.7.0.9" />
<PackageReference Include="MaterialDesignThemes" Version="4.9.0" />

<!-- Persian Support -->
<PackageReference Include="PersianDateTime" Version="2.5.0" />

<!-- Reporting -->
<PackageReference Include="Stimulsoft.Reports.WPF" Version="2024.1.2" />

<!-- Data Import/Export -->
<PackageReference Include="ClosedXML" Version="0.102.1" />
<PackageReference Include="CsvHelper" Version="31.0.2" />
<PackageReference Include="iTextSharp" Version="5.5.13.3" />

<!-- Security -->
<PackageReference Include="BCrypt.Net-Next" Version="4.0.3" />
```

---

## Database Design

### Entity Relationship Overview

#### Core Accounting Tables
```sql
-- Chart of Accounts (5-Level Structure)
CREATE TABLE ChartOfAccounts (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    AccountCode NVARCHAR(20) NOT NULL UNIQUE,
    ParentId UNIQUEIDENTIFIER NULL,
    AccountName NVARCHAR(100) NOT NULL,
    AccountNameEn NVARCHAR(100) NULL,
    Level INT NOT NULL,
    NormalBalance NVARCHAR(10) NOT NULL, -- DEBIT/CREDIT
    IsActive BIT NOT NULL DEFAULT 1,
    FOREIGN KEY (ParentId) REFERENCES ChartOfAccounts(Id)
);

-- Journal Entries
CREATE TABLE JournalEntries (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    DocumentNumber NVARCHAR(20) NOT NULL UNIQUE,
    EntryDate DATE NOT NULL,
    Description NVARCHAR(500),
    IsPosted BIT NOT NULL DEFAULT 0,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE()
);

-- Journal Entry Lines
CREATE TABLE JournalEntryLines (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    JournalEntryId UNIQUEIDENTIFIER NOT NULL,
    AccountId UNIQUEIDENTIFIER NOT NULL,
    SubAccountId UNIQUEIDENTIFIER NULL,
    Description NVARCHAR(200),
    DebitAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    CreditAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (JournalEntryId) REFERENCES JournalEntries(Id),
    FOREIGN KEY (AccountId) REFERENCES ChartOfAccounts(Id)
);
```

#### Inventory Management
```sql
-- Inventory Items
CREATE TABLE InventoryItems (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    ItemCode NVARCHAR(20) NOT NULL UNIQUE,
    ItemName NVARCHAR(100) NOT NULL,
    UnitOfMeasure NVARCHAR(20) NOT NULL,
    ItemType NVARCHAR(20) NOT NULL, -- RAW_MATERIAL, FINISHED_GOOD, etc.
    StandardCost DECIMAL(18,4) NOT NULL DEFAULT 0,
    SalePrice DECIMAL(18,4) NOT NULL DEFAULT 0,
    VATRate DECIMAL(5,2) NOT NULL DEFAULT 0
);

-- Inventory Movements
CREATE TABLE InventoryMovements (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    ItemId UNIQUEIDENTIFIER NOT NULL,
    MovementType NVARCHAR(10) NOT NULL, -- IN, OUT, ADJ
    Quantity DECIMAL(18,4) NOT NULL,
    UnitCost DECIMAL(18,4) NOT NULL,
    TotalAmount DECIMAL(18,2) NOT NULL,
    MovementDate DATETIME2 NOT NULL,
    ReferenceType NVARCHAR(20) NOT NULL, -- SALE, PURCHASE, PRODUCTION
    ReferenceId UNIQUEIDENTIFIER NULL,
    FOREIGN KEY (ItemId) REFERENCES InventoryItems(Id)
);

-- Stock Levels (Current balances)
CREATE TABLE InventoryStockLevels (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    ItemId UNIQUEIDENTIFIER NOT NULL,
    WarehouseId UNIQUEIDENTIFIER NULL,
    CurrentQuantity DECIMAL(18,4) NOT NULL DEFAULT 0,
    AverageCost DECIMAL(18,4) NOT NULL DEFAULT 0,
    LastUpdated DATETIME2 NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (ItemId) REFERENCES InventoryItems(Id)
);
```

#### Sales & Purchase Management
```sql
-- Sales Invoices
CREATE TABLE SalesInvoices (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    InvoiceNumber NVARCHAR(20) NOT NULL UNIQUE,
    CustomerId UNIQUEIDENTIFIER NOT NULL,
    InvoiceDate DATE NOT NULL,
    DueDate DATE NULL,
    SubTotal DECIMAL(18,2) NOT NULL DEFAULT 0,
    DiscountAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    TaxAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    TotalAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    Status NVARCHAR(20) NOT NULL DEFAULT 'DRAFT', -- DRAFT, APPROVED, PAID
    FOREIGN KEY (CustomerId) REFERENCES Customers(Id)
);

-- Sales Invoice Items
CREATE TABLE SalesInvoiceItems (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    InvoiceId UNIQUEIDENTIFIER NOT NULL,
    ItemId UNIQUEIDENTIFIER NOT NULL,
    Quantity DECIMAL(18,4) NOT NULL,
    UnitPrice DECIMAL(18,4) NOT NULL,
    UnitCost DECIMAL(18,4) NOT NULL,
    LineTotal DECIMAL(18,2) NOT NULL,
    TaxRate DECIMAL(5,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (InvoiceId) REFERENCES SalesInvoices(Id),
    FOREIGN KEY (ItemId) REFERENCES InventoryItems(Id)
);
```

### Database Schema Highlights

#### 1. 5-Level Chart of Accounts
```
Level 1: Main Categories (1-Assets, 2-Liabilities, 3-Equity, 4-Revenue, 5-Expenses)
Level 2: Sub-Categories (11-Current Assets, 12-Fixed Assets, etc.)
Level 3: Account Groups (111-Cash & Banks, 112-Receivables, etc.)
Level 4: Sub-Groups (1111-Cash in Hand, 1112-Bank Accounts, etc.)
Level 5: Detail Accounts (11111-Main Cash, 11112-Petty Cash, etc.)
```

#### 2. Hierarchical Account Structure
```sql
WITH AccountHierarchy AS (
    SELECT Id, AccountCode, AccountName, ParentId, Level, 0 as Depth
    FROM ChartOfAccounts 
    WHERE ParentId IS NULL
    
    UNION ALL
    
    SELECT c.Id, c.AccountCode, c.AccountName, c.ParentId, c.Level, h.Depth + 1
    FROM ChartOfAccounts c
    INNER JOIN AccountHierarchy h ON c.ParentId = h.Id
)
SELECT * FROM AccountHierarchy;
```

#### 3. Audit Trail Implementation
```sql
CREATE TABLE AuditTrail (
    Id UNIQUEIDENTIFIER PRIMARY KEY,
    TableName NVARCHAR(100) NOT NULL,
    RecordId UNIQUEIDENTIFIER NOT NULL,
    Operation NVARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    OldValues NVARCHAR(MAX) NULL,
    NewValues NVARCHAR(MAX) NULL,
    UserId UNIQUEIDENTIFIER NOT NULL,
    Timestamp DATETIME2 NOT NULL DEFAULT GETDATE()
);
```

---

## Business Logic

### Rule-Based Posting Engine

The system implements a sophisticated rule-based engine for automatic journal entry creation:

#### 1. Sales Transaction Posting Rules
```csharp
// When a sales invoice is approved:
// DR: Accounts Receivable - Customer
// CR: Sales Revenue
// CR: Sales Tax Payable (if applicable)
// DR: Cost of Goods Sold
// CR: Inventory

public async Task PostSalesInvoice(SalesInvoice invoice)
{
    var entries = new List<JournalEntryLine>();
    
    // Customer receivable
    entries.Add(new JournalEntryLine
    {
        AccountId = GetReceivablesAccountId(),
        SubAccountId = invoice.CustomerId,
        DebitAmount = invoice.TotalAmount,
        Description = $"Sales Invoice {invoice.InvoiceNumber}"
    });
    
    // Sales revenue
    entries.Add(new JournalEntryLine
    {
        AccountId = GetSalesRevenueAccountId(),
        CreditAmount = invoice.SubTotal - invoice.DiscountAmount,
        Description = "Sales Revenue"
    });
    
    // Sales tax
    if (invoice.TaxAmount > 0)
    {
        entries.Add(new JournalEntryLine
        {
            AccountId = GetSalesTaxAccountId(),
            CreditAmount = invoice.TaxAmount,
            Description = "Sales Tax"
        });
    }
    
    await PostJournalEntriesAsync(entries, invoice.InvoiceDate);
}
```

#### 2. Inventory Costing Algorithms
```csharp
public class InventoryCostingService
{
    public async Task<decimal> CalculateUnitCost(Guid itemId, string method)
    {
        switch (method.ToUpper())
        {
            case "FIFO":
                return await CalculateFIFOCost(itemId);
            case "AVERAGE":
                return await CalculateAverageCost(itemId);
            case "STANDARD":
                return await GetStandardCost(itemId);
            default:
                throw new ArgumentException("Invalid costing method");
        }
    }
    
    private async Task<decimal> CalculateAverageCost(Guid itemId)
    {
        var movements = await GetItemMovements(itemId);
        var totalValue = movements.Where(m => m.MovementType == "IN")
                                 .Sum(m => m.Quantity * m.UnitCost);
        var totalQuantity = movements.Where(m => m.MovementType == "IN")
                                   .Sum(m => m.Quantity);
        
        return totalQuantity > 0 ? totalValue / totalQuantity : 0;
    }
}
```

#### 3. Persian Payroll Calculations
```csharp
public class IranianPayrollCalculator
{
    public PayrollResult CalculatePayroll(Employee employee, PayrollPeriod period)
    {
        var basicSalary = employee.BasicSalary;
        var overtime = CalculateOvertime(employee, period);
        var grossSalary = basicSalary + overtime;
        
        // Iranian income tax calculation (progressive rates)
        var incomeTax = CalculateIncomeTax(grossSalary);
        
        // Social security (7% employee, 23% employer)
        var socialSecurityBase = Math.Min(grossSalary, GetSocialSecurityCeiling());
        var socialSecurityEmployee = socialSecurityBase * 0.07m;
        var socialSecurityEmployer = socialSecurityBase * 0.23m;
        
        // Unemployment insurance (0.5% employee, 1.5% employer)
        var unemploymentEmployee = socialSecurityBase * 0.005m;
        var unemploymentEmployer = socialSecurityBase * 0.015m;
        
        var netSalary = grossSalary - incomeTax - socialSecurityEmployee - unemploymentEmployee;
        
        return new PayrollResult
        {
            GrossSalary = grossSalary,
            IncomeTax = incomeTax,
            SocialSecurityEmployee = socialSecurityEmployee,
            SocialSecurityEmployer = socialSecurityEmployer,
            NetSalary = netSalary
        };
    }
}
```

---

## User Interface

### MVVM Pattern Implementation

#### 1. View Models
```csharp
public class JournalEntryViewModel : ViewModelBase
{
    private readonly IAccountingService _accountingService;
    private ObservableCollection<JournalEntryLineViewModel> _journalEntryLines;
    
    public ICommand SaveCommand { get; private set; }
    public ICommand PostCommand { get; private set; }
    public ICommand AddLineCommand { get; private set; }
    
    public JournalEntryViewModel(IAccountingService accountingService)
    {
        _accountingService = accountingService;
        InitializeCommands();
        JournalEntryLines = new ObservableCollection<JournalEntryLineViewModel>();
    }
    
    private async Task SaveJournalEntry()
    {
        if (!ValidateJournalEntry()) return;
        
        var dto = MapToDto();
        await _accountingService.CreateJournalEntryAsync(dto);
        
        ShowSuccessMessage("Journal entry saved successfully");
    }
}
```

#### 2. Data Binding with Persian Support
```xml
<DataGrid ItemsSource="{Binding JournalEntryLines}" 
          FlowDirection="RightToLeft"
          AutoGenerateColumns="False">
    <DataGrid.Columns>
        <DataGridTextColumn Header="کد حساب" 
                           Binding="{Binding AccountCode}" 
                           Width="120"/>
        <DataGridTextColumn Header="نام حساب" 
                           Binding="{Binding AccountName}" 
                           Width="*"/>
        <DataGridTextColumn Header="بدهکار" 
                           Binding="{Binding DebitAmount, StringFormat=N0}" 
                           Width="120"/>
        <DataGridTextColumn Header="بستانکار" 
                           Binding="{Binding CreditAmount, StringFormat=N0}" 
                           Width="120"/>
    </DataGrid.Columns>
</DataGrid>
```

#### 3. Custom Persian Date Picker
```xml
<UserControl x:Class="MEHSAB.Controls.PersianDatePicker">
    <Grid>
        <TextBox Name="txtDate" 
                 Text="{Binding SelectedPersianDate}" 
                 IsReadOnly="True"/>
        <Button Name="btnCalendar" 
                Content="📅" 
                Click="ShowCalendar_Click"/>
        <Popup Name="popupCalendar" 
               StaysOpen="False">
            <!-- Persian Calendar Implementation -->
        </Popup>
    </Grid>
</UserControl>
```

---

## Security Architecture

### 1. Authentication & Authorization
```csharp
public class SecurityService : ISecurityService
{
    public async Task<AuthenticationResult> AuthenticateAsync(string username, string password)
    {
        var user = await _userRepository.GetByUsernameAsync(username);
        
        if (user == null || !BCrypt.Net.BCrypt.Verify(password, user.PasswordHash))
        {
            await LogFailedLoginAttemptAsync(username);
            return AuthenticationResult.Failed("Invalid credentials");
        }
        
        if (user.IsLocked)
        {
            return AuthenticationResult.Failed("Account is locked");
        }
        
        var token = GenerateJwtToken(user);
        await LogSuccessfulLoginAsync(user);
        
        return AuthenticationResult.Success(token, user);
    }
}
```

### 2. Data Encryption
```csharp
public class EncryptionService : IEncryptionService
{
    private readonly byte[] _key;
    private readonly byte[] _iv;
    
    public string Encrypt(string plainText)
    {
        using var aes = Aes.Create();
        aes.Key = _key;
        aes.IV = _iv;
        
        using var encryptor = aes.CreateEncryptor();
        using var ms = new MemoryStream();
        using var cs = new CryptoStream(ms, encryptor, CryptoStreamMode.Write);
        using var writer = new StreamWriter(cs);
        
        writer.Write(plainText);
        return Convert.ToBase64String(ms.ToArray());
    }
}
```

### 3. Audit Trail
```csharp
public class AuditService : IAuditService
{
    public async Task LogOperationAsync(string tableName, Guid recordId, 
                                       string operation, object oldValues, 
                                       object newValues, Guid userId)
    {
        var auditEntry = new AuditTrail
        {
            TableName = tableName,
            RecordId = recordId,
            Operation = operation,
            OldValues = JsonSerializer.Serialize(oldValues),
            NewValues = JsonSerializer.Serialize(newValues),
            UserId = userId,
            Timestamp = DateTime.UtcNow
        };
        
        await _auditRepository.AddAsync(auditEntry);
    }
}
```

---

## Integration Points

### 1. Tax Payer System Integration (Samaneh Modian)
```csharp
public class TaxPayerService : ITaxPayerService
{
    public async Task<bool> SendInvoiceAsync(SalesInvoice invoice)
    {
        var taxPayerData = new
        {
            header = new
            {
                taxid = invoice.Customer.TaxId,
                indatim = ConvertToUnixTimestamp(invoice.InvoiceDate),
                inty = 1, // Invoice type
                inno = invoice.InvoiceNumber
            },
            body = invoice.Items.Select(item => new
            {
                sstid = GetServiceCode(item),
                sstt = item.Description,
                am = item.Quantity,
                fee = item.UnitPrice,
                cfee = item.LineTotal
            })
        };
        
        var json = JsonSerializer.Serialize(taxPayerData);
        var signature = SignData(json);
        
        var response = await _httpClient.PostAsync(
            "https://tp.tax.gov.ir/api/v1/invoice",
            new StringContent(json, Encoding.UTF8, "application/json"));
            
        return response.IsSuccessStatusCode;
    }
}
```

### 2. Reporting Engine Integration
```csharp
public class StimulsoftReportService : IReportService
{
    public async Task<byte[]> GenerateReportAsync(string reportName, object data, 
                                                 ReportFormat format)
    {
        var report = new StiReport();
        report.Load($"Reports\\{reportName}.mrt");
        
        // Persian font configuration
        report.RegBusinessObject("Data", data);
        report.Render();
        
        using var stream = new MemoryStream();
        
        switch (format)
        {
            case ReportFormat.PDF:
                report.ExportDocument(StiExportFormat.Pdf, stream);
                break;
            case ReportFormat.Excel:
                report.ExportDocument(StiExportFormat.Excel2007, stream);
                break;
        }
        
        return stream.ToArray();
    }
}
```

---

## Deployment Architecture

### 1. Single-User Desktop Deployment
```
[User Workstation]
├── MEHSAB.exe (WPF Application)
├── SQL Server LocalDB
├── Application Files
└── Data Files (Encrypted)
```

### 2. Multi-User Network Deployment
```
[Database Server]
├── SQL Server Express/Standard
├── Central Database
└── Backup Files

[Client Workstations]
├── MEHSAB.exe (WPF Client)
├── Network Connection
└── Local Cache
```

### 3. Installation Components
```xml
<!-- WiX Installer Configuration -->
<Package Id="*" 
         Name="MEHSAB Accounting System" 
         Language="1033" 
         Version="1.0.0.0" 
         Manufacturer="MEHSAB Solutions"
         UpgradeCode="12345678-1234-1234-1234-123456789012">
  
  <Feature Id="MainApplication" Title="Main Application" Level="1">
    <ComponentRef Id="ApplicationFiles" />
    <ComponentRef Id="DatabaseFiles" />
    <ComponentRef Id="ReportFiles" />
  </Feature>
  
  <Feature Id="Prerequisites" Title="Prerequisites" Level="1">
    <ComponentRef Id="DotNetRuntime" />
    <ComponentRef Id="SqlLocalDB" />
  </Feature>
</Package>
```

---

## Performance Considerations

### 1. Database Optimization
```sql
-- Indexes for optimal performance
CREATE INDEX IX_JournalEntryLines_AccountId_EntryDate 
ON JournalEntryLines (AccountId, JournalEntryId)
INCLUDE (DebitAmount, CreditAmount);

CREATE INDEX IX_InventoryMovements_ItemId_MovementDate 
ON InventoryMovements (ItemId, MovementDate DESC)
INCLUDE (Quantity, UnitCost, MovementType);

-- Partitioning for large datasets
CREATE PARTITION SCHEME ps_JournalEntries
AS PARTITION pf_Date
TO (fg_2023, fg_2024, fg_2025);
```

### 2. Caching Strategy
```csharp
public class CacheService : ICacheService
{
    private readonly IMemoryCache _cache;
    private readonly TimeSpan _defaultExpiration = TimeSpan.FromMinutes(30);
    
    public async Task<T> GetOrSetAsync<T>(string key, Func<Task<T>> factory)
    {
        if (_cache.TryGetValue(key, out T cachedValue))
        {
            return cachedValue;
        }
        
        var value = await factory();
        _cache.Set(key, value, _defaultExpiration);
        
        return value;
    }
}
```

### 3. Lazy Loading and Pagination
```csharp
public async Task<PagedResult<JournalEntry>> GetJournalEntriesAsync(
    int page, int pageSize, DateTime? fromDate = null, DateTime? toDate = null)
{
    var query = _context.JournalEntries.AsQueryable();
    
    if (fromDate.HasValue)
        query = query.Where(je => je.EntryDate >= fromDate);
    
    if (toDate.HasValue)
        query = query.Where(je => je.EntryDate <= toDate);
    
    var totalCount = await query.CountAsync();
    
    var items = await query
        .OrderByDescending(je => je.EntryDate)
        .Skip((page - 1) * pageSize)
        .Take(pageSize)
        .ToListAsync();
    
    return new PagedResult<JournalEntry>
    {
        Items = items,
        TotalCount = totalCount,
        Page = page,
        PageSize = pageSize
    };
}
```

---

## Conclusion

MEHSAB represents a comprehensive, enterprise-grade accounting solution built with modern .NET technologies and Persian business requirements in mind. The system's layered architecture ensures maintainability and extensibility while the rule-based engine provides flexible business logic implementation.

The system's strength lies in its:
- **Robust Architecture**: DDD principles ensure business logic is properly encapsulated
- **Persian Compliance**: Full support for Iranian accounting standards and regulations
- **Comprehensive Features**: Complete accounting, inventory, sales, and financial management
- **Professional UI**: Modern WPF interface with Persian RTL support
- **Integration Ready**: Built-in support for Tax Payer System and reporting engines
- **Security First**: Comprehensive audit trail and data encryption
- **Performance Optimized**: Caching, indexing, and efficient data access patterns

This technical documentation provides the foundation for understanding, maintaining, and extending the MEHSAB system according to evolving business requirements.