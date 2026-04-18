-- =========================
-- 0) DATABASE
-- =========================
CREATE DATABASE VehicleInspectionCenter;
GO
USE VehicleInspectionCenter;
GO


-- =========================
-- 1) NHÓM NGƯỜI DÙNG - NHÂN SỰ - PHÂN QUYỀN
-- =========================
CREATE TABLE dbo.Role(
    RoleId      INT IDENTITY(1,1) PRIMARY KEY,
    RoleCode    NVARCHAR(50) NOT NULL UNIQUE,   
	RoleAcronym NVARCHAR(50) NOT NULL,
    RoleName    NVARCHAR(255) NOT NULL,
	RoleIcon    NVARCHAR(255),
	RoleHref    NVARCHAR(255)
);

CREATE TABLE Position(
	PositionId  INT IDENTITY(1,1) PRIMARY KEY,
	PoitionCode NVARCHAR(100) NOT NULL,
	PositionName NVARCHAR(100) NOT NULL,
)

CREATE TABLE Team(
	TeamId  INT IDENTITY(1,1) PRIMARY KEY,
	TeamCode NVARCHAR(100) NOT NULL,
	TeamName NVARCHAR(100) NOT NULL,
)

CREATE TABLE PositionTeam (
    PositionId INT NOT NULL,
    TeamId INT NOT NULL,
    PRIMARY KEY (PositionId, TeamId),
    CONSTRAINT FK_PT_Position FOREIGN KEY (PositionId) REFERENCES Position(PositionId),
    CONSTRAINT FK_PT_Team FOREIGN KEY (TeamId) REFERENCES Team(TeamId)
);

CREATE TABLE dbo.[User] (
    UserId          UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FullName        NVARCHAR(120) NOT NULL,
    Phone           NVARCHAR(20)  NOT NULL,
    Email           NVARCHAR(120) NOT NULL,
	BirthDate		DATE NULL,
	CCCD			NVARCHAR(20)  NOT NULL,
	[Address] NVARCHAR(100),
	Ward NVARCHAR(100),
	Province NVARCHAR(100),
	Gender			NVARCHAR(10),
	ImageUrl		NVARCHAR(255),  -- Sau này cần bổ sung thêm default
	PositionId		INT DEFAULT 1,          -- Giám đốc / Phó / KTV / NV nghiệp vụ / Kế toán...
	TeamId			INT DEFAULT 1,         -- Ban giám đốc / Tổ kiểm định / Tổ nghiệp vụ / Tổ kế toán (nếu bạn muốn lưu)
	[Level]			NVARCHAR(50),
    IsActive        BIT NOT NULL DEFAULT 1,
    CreatedAt       DATETIME NOT NULL DEFAULT GETDATE(),
	FOREIGN KEY (PositionId) REFERENCES Position(PositionId),
	FOREIGN KEY (TeamId) REFERENCES Team(TeamId)
);
ALTER TABLE [User] ADD CONSTRAINT UQ_User_Phone UNIQUE(Phone);
ALTER TABLE [User] ADD CONSTRAINT UQ_User_CCCD UNIQUE(CCCD);
ALTER TABLE [User] ADD CONSTRAINT UQ_User_Email UNIQUE(Email);

ALTER TABLE [User] ADD Address NVARCHAR(100);
ALTER TABLE [User] ADD Ward NVARCHAR(100);
ALTER TABLE [User] ADD Province NVARCHAR(100);


CREATE TABLE dbo.Account (
    UserId          UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    Username        NVARCHAR(50) NULL,
    PasswordHash    NVARCHAR(255) NULL,
    IsLocked        BIT NOT NULL DEFAULT 0,
    FailedCount     INT NOT NULL DEFAULT 0,  -- Số lần thất bại
    LastLoginAt     DATETIME2 NULL,  -- Lần đăng nhập cuối cùng
    CONSTRAINT FK_Account_User FOREIGN KEY (UserId) REFERENCES dbo.[User](UserId) ON DELETE CASCADE
);
-- Tạo unique index có điều kiện
CREATE UNIQUE INDEX UX_Account_Username_NotNull
ON dbo.Account (Username)
WHERE Username IS NOT NULL;

CREATE TABLE PasswordRecovery(
	PasswordRecoveryId INT PRIMARY KEY IDENTITY(1,1),
	UserId          UNIQUEIDENTIFIER NOT NULL,
	ResetOtpHash    NVARCHAR(200) NULL,
    ResetOtpExpiresAt DATETIME2 NULL,
    ResetOtpAttemptCount INT NOT NULL CONSTRAINT DF_Users_ResetOtpAttemptCount DEFAULT(0),
	FOREIGN KEY (UserId) REFERENCES [User](UserId) ON DELETE CASCADE
)

CREATE TABLE dbo.User_Role (
    UserId  UNIQUEIDENTIFIER NOT NULL,
    RoleId  INT NOT NULL,
    PRIMARY KEY (UserId, RoleId),
    FOREIGN KEY (UserId) REFERENCES dbo.[User](UserId) ON DELETE CASCADE,
    FOREIGN KEY (RoleId) REFERENCES dbo.Role(RoleId) ON DELETE CASCADE
);

-- 2.Bảng Stage 
CREATE TABLE dbo.Stage (
    StageId     INT IDENTITY(1,1) PRIMARY KEY,
    StageCode   NVARCHAR(30) NOT NULL UNIQUE,
    StageName   NVARCHAR(120) NOT NULL, 
    -- SortOrder   INT NOT NULL,
    IsActive    BIT DEFAULT 1         
);

-- Gán KTV được phép làm công đoạn nào
CREATE TABLE dbo.UserStage (
    UserId  UNIQUEIDENTIFIER NOT NULL,
    StageId INT NOT NULL,
    PRIMARY KEY (UserId, StageId),
    FOREIGN KEY (UserId) REFERENCES dbo.[User](UserId) ON DELETE CASCADE,
    FOREIGN KEY (StageId) REFERENCES dbo.Stage(StageId) ON DELETE CASCADE
);

-- =========================
-- 2) NHÓM CHỦ XE PHƯƠNG TIỆN
-- =========================
CREATE TABLE dbo.Owner (
    OwnerId         UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    OwnerType       NVARCHAR(20) NOT NULL DEFAULT N'PERSON',  -- PERSON / COMPANY
    FullName        NVARCHAR(150) NOT NULL,
	CompanyName         NVARCHAR(200) NULL,
    TaxCode             NVARCHAR(30)  NULL, -- MST
    CCCD            NVARCHAR(30) NULL,  
    Phone           NVARCHAR(20) NULL UNIQUE,
    Email           NVARCHAR(120) NULL,
    Address         NVARCHAR(255) NULL,
    CreatedAt       DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);

ALTER TABLE dbo.Owner
Add Ward NVARCHAR(100), Province NVARCHAR(100);

ALTER TABLE dbo.Owner
Add ImageUrl NVARCHAR(255);

-- 5.Bảng VehicleType (Loại xe đề sắp tiêu chuẩn đánh già)
CREATE TABLE dbo.VehicleType (
    VehicleTypeId INT IDENTITY(1,1) PRIMARY KEY,
    TypeCode      NVARCHAR(20) NOT NULL UNIQUE,
    TypeName      NVARCHAR(100) NOT NULL,
    Description   NVARCHAR(500) NULL,
    IsActive      BIT DEFAULT 1
);

CREATE TABLE dbo.Vehicle(
    VehicleId               INT IDENTITY(1,1) PRIMARY KEY,
    
    -- THÔNG TIN CƠ BẢN
    PlateNo                 NVARCHAR(20) NOT NULL,              -- Biển đăng ký (Registration plate)
    InspectionNo            NVARCHAR(50) NULL,                         -- Số quản lý phương tiện (Vehicle inspection N°)
    
    -- PHÂN LOẠI
    VehicleGroup            NVARCHAR(100) NULL,                        -- Nhóm phương tiện (Vehicle's group)
    VehicleTypeId            INT,                        -- Loại phương tiện (Vehicle's type)
    
    -- NĂNG LƯỢNG & MỤC ĐÍCH SỬ DỤNG
    EnergyType              NVARCHAR(50) NULL,                         -- Sử dụng năng lượng sạch, xanh, thân thiện môi trường
    IsCleanEnergy           BIT NULL DEFAULT 0,                        -- Clean, green energy vehicle
    UsagePermission         NVARCHAR(20) NULL,                         -- Cho phép tự động lái / Một phần / Toàn phần
                                                                       -- (Drive automation: Partially / Fully)
    
    -- THƯƠNG HIỆU & MODEL
    Brand                   NVARCHAR(100) NULL,                        -- Nhãn hiệu, tên thương mại (Trademark, Commercial name)
    Model                   NVARCHAR(100) NULL,                        -- Mã kiểu loại (Model code)
    
    -- THÔNG SỐ ĐỘNG CƠ & KHUNG XE
    EngineNo                NVARCHAR(50) NULL,                         -- Số động cơ (Engine N°)
    Chassis                 NVARCHAR(50) NULL,                         -- Số khung (Chassis N°)
    
    -- XUẤT XỨ
    ManufactureYear         INT NULL,                                  -- Năm (Production year)
    ManufactureCountry      NVARCHAR(100) NULL,                        -- Nước sản xuất (Country)
    LifetimeLimitYear       INT NULL,                                  -- Niên hạn sử dụng (Lifetime Limit in)
    
    -- CẢI TẠO
    HasCommercialModification BIT NULL DEFAULT 0,                      -- Có kinh doanh vận tải (Commercial use)
    HasModification         BIT NULL DEFAULT 0,                        -- Có cải tạo (Modification)
    
    -- QUAN HỆ CHỦ XE
    OwnerId                 UNIQUEIDENTIFIER NOT NULL,
    
    -- TIMESTAMPS
    CreatedAt               DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt               DATETIME2 NULL,
    CreatedBy               UNIQUEIDENTIFIER NULL,
    UpdatedBy               UNIQUEIDENTIFIER NULL,
    
    FOREIGN KEY (OwnerId) REFERENCES dbo.Owner(OwnerId),
    FOREIGN KEY (CreatedBy) REFERENCES dbo.[User](UserId),
    FOREIGN KEY (UpdatedBy) REFERENCES dbo.[User](UserId),
	FOREIGN KEY (VehicleTypeId) REFERENCES dbo.VehicleType(VehicleTypeId),
	CONSTRAINT UQ_Vehicle_PlateNo UNIQUE (PlateNo)
);

CREATE TABLE dbo.Specification (
    SpecificationId         INT IDENTITY(1,1) PRIMARY KEY,
    PlateNo                 NVARCHAR(20) NOT NULL UNIQUE,  -- Tham chiếu đến Vehicle.PlateNo
    
    -- KÍCH THƯỚC - THÔNG SỐ KỸ THUẬT (SPECIFICATIONS)
    WheelFormula            NVARCHAR(50) NULL,             -- Công thức bánh xe: 4x2, 6x4
    WheelTread              INT NULL,                      -- Vết bánh xe (mm)
    
    -- Kích thước bao (Overall dimensions)
    OverallLength           INT NULL,                      -- Chiều dài (mm)
    OverallWidth            INT NULL,                      -- Chiều rộng (mm)
    OverallHeight           INT NULL,                      -- Chiều cao (mm)
    
    -- Kích thước lòng bao thùng xe 
    CargoInsideLength       INT NULL,                      -- Dài (mm)
    CargoInsideWidth        INT NULL,                      -- Rộng (mm)
    CargoInsideHeight       INT NULL,                      -- Cao (mm)
    
    -- Khoảng cách trục (Wheel base)
    Wheelbase               INT NULL,                      -- (mm)
    
    -- KHỐI LƯỢNG (WEIGHT)
    KerbWeight              DECIMAL(10,2) NULL,            -- Khối lượng bản thân (kg)
    AuthorizedCargoWeight   DECIMAL(10,2) NULL,            -- Khối lượng hàng CC theo TK/CP-N (kg)
    AuthorizedTowedWeight   DECIMAL(10,2) NULL,            -- Khối lượng kéo theo TK/CP-N (kg)
    AuthorizedTotalWeight   DECIMAL(10,2) NULL,            -- Khối lượng toàn bộ theo TK/CP-N (kg)
    
    -- Số người cho phép chở
    SeatingCapacity         INT NULL,                      -- Chở ngồi
    StandingCapacity        INT NULL,                      -- Chở đứng
    LyingCapacity           INT NULL,                      -- Chở nằm
    
    -- ĐỘNG CƠ (ENGINE)
    EngineType              NVARCHAR(100) NULL,            -- Loại động cơ
    EnginePosition          NVARCHAR(50) NULL,             -- Vị trí đặt động cơ
    EngineModel             NVARCHAR(50) NULL,             -- Ký hiệu động cơ
    EngineDisplacement      INT NULL,                      -- Thể tích làm việc (cm³)
    MaxPower                DECIMAL(10,2) NULL,            -- Công suất lớn nhất (kW)
    MaxPowerRPM             INT NULL,                      -- Tốc độ quay tại công suất max (rpm)
    FuelType                NVARCHAR(50) NULL,             -- Loại nhiên liệu
    
    -- ĐỘNG CƠ ĐIỆN (MOTOR)
    MotorType               NVARCHAR(100) NULL,            -- Loại động cơ điện
    NumberOfMotors          INT NULL,                      -- Số lượng động cơ điện
    MotorModel              NVARCHAR(50) NULL,             -- Ký hiệu động cơ điện
    TotalMotorPower         DECIMAL(10,2) NULL,            -- Tổng công suất (kW)
    MotorVoltage            DECIMAL(10,2) NULL,            -- Điện áp (V)
    
    -- ẮC QUY (BATTERY)
    BatteryType             NVARCHAR(100) NULL,            -- Loại ắc quy
    BatteryVoltage          DECIMAL(10,2) NULL,            -- Điện áp (V)
    BatteryCapacity         DECIMAL(10,2) NULL,            -- Dung lượng (kWh)
    
    -- LỐP XE (TIRES)
    TireCount               INT NULL,                      -- Số lượng lốp
    TireSize                NVARCHAR(50) NULL,             -- Cỡ lốp
    TireAxleInfo            NVARCHAR(100) NULL,            -- Thông tin trục
       
    -- VỊ TRÍ THIẾT BỊ
    ImagePosition           NVARCHAR(100) NULL,            -- Vị trí hình ảnh
    
    -- TRANG THIẾT BỊ đẩy xuống kia 5.3
    HasTachograph           BIT NULL DEFAULT 0,            -- Có thiết bị giám sát hành trình
    HasDriverCamera         BIT NULL DEFAULT 0,            -- Có camera ghi nhận lái xe
    NotIssuedStamp          BIT NULL DEFAULT 0,            -- PT không được cấp tem
    
    -- GHI CHÚ
    Notes                   NVARCHAR(1000) NULL,
    
    -- TIMESTAMPS
    CreatedAt               DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt               DATETIME2 NULL,
    CreatedBy               UNIQUEIDENTIFIER NULL,
    UpdatedBy               UNIQUEIDENTIFIER NULL,
    
    FOREIGN KEY (PlateNo) REFERENCES dbo.Vehicle(PlateNo) ON DELETE CASCADE,
    FOREIGN KEY (CreatedBy) REFERENCES dbo.[User](UserId),
    FOREIGN KEY (UpdatedBy) REFERENCES dbo.[User](UserId)
);

-- =========================
-- 3) NHÓM CẤU HÌNH DÂY TRUYỀN - CÔNG ĐOẠN - CHỈ TIÊU
-- =========================
-- 1. Bảng Lane
CREATE TABLE dbo.Lane (
    LaneId      INT IDENTITY(1,1) PRIMARY KEY,
    LaneCode    NVARCHAR(20) NOT NULL UNIQUE,
    LaneName    NVARCHAR(100) NOT NULL,
    IsActive    BIT NOT NULL DEFAULT 1
);


-- 3.Bảng LaneStage
CREATE TABLE dbo.LaneStage (
    LaneStageId INT IDENTITY(1,1) PRIMARY KEY,
    LaneId      INT NOT NULL,
    StageId     INT NOT NULL,
    SortOrder   INT NOT NULL,   
    IsRequired  BIT DEFAULT 1,        -- Bắt buộc hay tùy chọn
    IsActive    BIT DEFAULT 1,
    
    FOREIGN KEY (LaneId) REFERENCES dbo.Lane(LaneId),
    FOREIGN KEY (StageId) REFERENCES dbo.Stage(StageId),
    CONSTRAINT UQ_LaneStage UNIQUE (LaneId, StageId)
);


-- 4.Bảng StageItem
CREATE TABLE dbo.StageItem (
    ItemId      INT IDENTITY(1,1) PRIMARY KEY,
    StageId     INT NOT NULL,
    ItemCode    NVARCHAR(40) NOT NULL,
    ItemName    NVARCHAR(160) NOT NULL,
    Unit        NVARCHAR(20) NULL,
    DataType    NVARCHAR(20) NOT NULL 
        CHECK (DataType IN ('NUMBER','TEXT','BOOL')),
    SortOrder   INT NULL,           
    Description NVARCHAR(500) NULL,  
    IsRequired  BIT NOT NULL DEFAULT 1,
    
    FOREIGN KEY (StageId) REFERENCES dbo.Stage(StageId),
    CONSTRAINT UQ_StageItem UNIQUE(StageId, ItemCode)
);



-- 6.Bảng StageItemThreshold (Tiêu chuẩn đánh giá)
CREATE TABLE dbo.StageItemThreshold (
    ThresholdId     INT IDENTITY(1,1) PRIMARY KEY,
    ItemId          INT NOT NULL,
    VehicleTypeId   INT NOT NULL,
    MinValue        DECIMAL(18,4) NULL,
    MaxValue        DECIMAL(18,4) NULL,
    PassCondition   NVARCHAR(200) NULL,  -- VD: "> 50 AND < 100"
    AllowedValues   NVARCHAR(500) NULL,  -- VD: "ĐẠT;KHÔNG ĐẠT;N/A"
    FailAction      NVARCHAR(20) NULL    -- STOP / WARN / CONTINUE
        CHECK (FailAction IN ('STOP','WARN','CONTINUE')),
    IsActive        BIT DEFAULT 1,
    EffectiveDate   DATE DEFAULT GETDATE(),
    
    FOREIGN KEY (ItemId) REFERENCES dbo.StageItem(ItemId),
    FOREIGN KEY (VehicleTypeId) REFERENCES dbo.VehicleType(VehicleTypeId),
    CONSTRAINT UQ_ItemVehicleDate 
    UNIQUE (ItemId, VehicleTypeId, EffectiveDate)
);

CREATE TABLE LaneVehicleType (
    LaneId INT NOT NULL,
    VehicleTypeId INT NOT NULL,

    CONSTRAINT PK_LaneVehicleType PRIMARY KEY (LaneId, VehicleTypeId),
    CONSTRAINT FK_LVT_Lane FOREIGN KEY (LaneId) REFERENCES Lane(LaneId),
    CONSTRAINT FK_LVT_VehicleType  FOREIGN KEY (VehicleTypeId) REFERENCES VehicleType(VehicleTypeId)
);


-- =========================
-- 4) NHÓM HỒ SƠ KIỂM ĐỊNH (LÕI NGHIỆP VỤ)
-- Status: 0 Draft, 1 Received, 2 Paid, 3 InProgress, 4 WaitingConclusion, 5 Passed, 6 Failed, 7 Cancelled
-- =========================
-- 4.1) Bảng Inspection (Hồ sơ kiểm định chính)
-- Trạng thái chính của hồ sơ theo quy trình thực tế
CREATE TABLE dbo.Inspection (
    InspectionId INT IDENTITY(1,1) PRIMARY KEY,
    InspectionCode NVARCHAR(30) NOT NULL UNIQUE,-- Mã lượt kiểm định
    
    -- THÔNG TIN PHƯƠNG TIỆN & CHỦ XE
    VehicleId INT NOT NULL,
    OwnerId UNIQUEIDENTIFIER NOT NULL,
    
    -- PHÂN LOẠI KIỂM ĐỊNH
    InspectionType NVARCHAR(20) NOT NULL DEFAULT N'FIRST',  
                        -- FIRST: Đăng kiểm lần đầu
                        -- PERIODIC: Định kỳ
                        -- RE_INSPECTION: Tái kiểm (sau khi sửa)
    --ParentInspectionId INT NULL,-- Liên kết tái kiểm với lượt trước
    
    -- PHÂN DÂY CHUYỀN
     LaneId INT NULL,-- Dây chuyền được gán
    
    -- TRẠNG THÁI QUY TRÌNH 
    Status SMALLINT NOT NULL DEFAULT 0,
    /*
        0: DRAFT           - Nháp (chưa tiếp nhận)
        1: RECEIVED        - Đã tiếp nhận (chờ thu phí)
        2: PAID            - Đã thu phí (chờ vào dây chuyền)
        3: IN_PROGRESS     - Đang kiểm định
        4: COMPLETED       - Hoàn thành kiểm định (chờ kết luận)
        5: PASSED          - Đạt (chờ cấp giấy)
        6: FAILED          - Không đạt (cần sửa chữa)
        7: CERTIFIED       - Đã cấp chứng nhận
        8: CANCELLED       - Hủy bỏ
    */
    
    -- KẾT LUẬN CUỐI CÙNG
    FinalResult INT NULL,                    
    /*
        NULL: Chưa có kết luận
        1: ĐẠT - Tất cả công đoạn đạt
        2: KHÔNG ĐẠT - Có công đoạn không đạt
        3: TẠM ĐÌNH CHỈ - Vi phạm nghiêm trọng
    */
    ConclusionNote NVARCHAR(1000) NULL,-- Ghi chú kết luận
    ConcludedBy UNIQUEIDENTIFIER NULL,-- Giám sát viên/Tổ trưởng kết luận
    ConcludedAt DATETIME2 NULL,
    
    -- THỜI GIAN QUY TRÌNH
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),  -- Tạo hồ sơ
    ReceivedAt DATETIME2 NULL,                   -- Tiếp nhận
    PaidAt DATETIME2 NULL,                   -- Thu phí xong
    StartedAt DATETIME2 NULL,                   -- Bắt đầu kiểm định
    CompletedAt DATETIME2 NULL,                   -- Hoàn thành kiểm định
    CertifiedAt DATETIME2 NULL,                   -- Cấp chứng nhận
    
    -- NGƯỜI THỰC HIỆN
    CreatedBy UNIQUEIDENTIFIER NULL, -- Người tạo (có thể là hệ thống hoặc NV tiếp nhận)
    ReceivedBy UNIQUEIDENTIFIER NULL, -- NV tiếp nhận hồ sơ
    
    -- GHI CHÚ & METADATA
    Notes               NVARCHAR(1000) NULL,-- Ghi chú chung
    -- Priority            SMALLINT DEFAULT 1,-- Mức ưu tiên (1: Thường, 2: Cao, 3: Khẩn cấp)
    IsDeleted           BIT NOT NULL DEFAULT 0,
	Count_Re INT,
    
    FOREIGN KEY (VehicleId) REFERENCES dbo.Vehicle(VehicleId),
    --FOREIGN KEY (OwnerId) REFERENCES dbo.Owner(OwnerId),
    --FOREIGN KEY (ParentInspectionId) REFERENCES dbo.Inspection(InspectionId),
    FOREIGN KEY (LaneId) REFERENCES dbo.Lane(LaneId),
    FOREIGN KEY (ConcludedBy) REFERENCES dbo.[User](UserId),
    FOREIGN KEY (CreatedBy) REFERENCES dbo.[User](UserId),
    FOREIGN KEY (ReceivedBy) REFERENCES dbo.[User](UserId),
    CONSTRAINT CK_Inspection_Status CHECK (Status BETWEEN 0 AND 8),
    CONSTRAINT CK_Inspection_FinalResult CHECK (FinalResult IN (1,2,3) OR FinalResult IS NULL),
   -- CONSTRAINT CK_Inspection_Priority CHECK (Priority BETWEEN 1 AND 3)
);

-- 4.2) Bảng InspectionStage (Chi tiết công đoạn kiểm định)
-- Mỗi hồ sơ sẽ có nhiều công đoạn tương ứng với dây chuyền
CREATE TABLE dbo.InspectionStage (
    InspStageId BIGINT IDENTITY(1,1) PRIMARY KEY,
    InspectionId INT NOT NULL,
    StageId INT NOT NULL,-- Công đoạn (Động cơ, Phanh, Đèn...)
    
    -- TRẠNG THÁI CÔNG ĐOẠN
    Status INT NOT NULL DEFAULT 0,
    /*
        0: PENDING     - Chờ thực hiện
        1: IN_PROGRESS - Đang thực hiện
        2: COMPLETED   - Hoàn thành
        3: ON_HOLD     - Tạm dừng (chờ thiết bị/sửa chữa)
        4: SKIPPED     - Bỏ qua (không áp dụng)
    */
    
    -- KẾT QUẢ CÔNG ĐOẠN
    StageResult INT NULL,
    /*
        NULL: Chưa có kết quả
        1: ĐẠT - Tất cả chỉ tiêu đạt
        2: KHÔNG ĐẠT - Có chỉ tiêu không đạt
        3: KHUYẾT ĐIỂM - Đạt nhưng có lỗi nhỏ cần lưu ý
    */
    
    
    -- GHI CHÚ
    Notes NVARCHAR(500) NULL,-- Ghi chú của KTV
    
    -- METADATA
    SortOrder INT NOT NULL DEFAULT 0,-- Thứ tự thực hiện
    IsRequired BIT NOT NULL DEFAULT 1,-- Bắt buộc hay không
    
    FOREIGN KEY (InspectionId) REFERENCES dbo.Inspection(InspectionId) ON DELETE CASCADE,
    FOREIGN KEY (StageId) REFERENCES dbo.Stage(StageId),
    CONSTRAINT CK_InspStage_Status CHECK (Status BETWEEN 0 AND 4),
    CONSTRAINT CK_InspStage_Result CHECK (StageResult IN (1,2,3) OR StageResult IS NULL),
    CONSTRAINT UQ_InspStage UNIQUE (InspectionId, StageId)
);

-- 4.3) Bảng InspectionDetail (Kết quả đo chi tiết từng chỉ tiêu)
CREATE TABLE dbo.InspectionDetail (
    DetailId INT IDENTITY(1,1) PRIMARY KEY,
    InspStageId BIGINT NOT NULL,-- Thuộc công đoạn nào
    ItemId INT NOT NULL,-- Chỉ tiêu nào
    
    -- TIÊU CHUẨN (Lấy từ StageItemThreshold theo VehicleType)
    StandardMin DECIMAL(18,4) NULL, -- Giá trị min theo tiêu chuẩn
    StandardMax DECIMAL(18,4) NULL, -- Giá trị max theo tiêu chuẩn
    --StandardText NVARCHAR(100) NULL, -- Tiêu chuẩn dạng text (VD: "Bình thường")
    
    -- GIÁ TRỊ ĐO ĐƯỢC
    ActualValue DECIMAL(18,4) NULL,-- Giá trị đo (số)
    --ActualText NVARCHAR(100) NULL, -- Giá trị đo (text)
    Unit NVARCHAR(20) NULL,-- Đơn vị (kg, N, lux, %)
    
    -- KẾT QUẢ ĐÁNH GIÁ
    IsPassed BIT NULL,-- Đạt chỉ tiêu này?
    /*
        NULL: Chưa đánh giá
        0: KHÔNG ĐẠT
        1: ĐẠT
    */
    --DeviationPercent DECIMAL(10,2) NULL,-- % chênh lệch so với tiêu chuẩn
    
    -- NGUỒN DỮ LIỆU
    DataSource NVARCHAR(20) NOT NULL DEFAULT N'MANUAL',
    /*
        MANUAL: Nhập tay
        DEVICE: Từ thiết bị đo
        VISUAL: Kiểm tra mắt thường
        CALCULATED: Tính toán
    */
    --DeviceId NVARCHAR(50) NULL,-- ID thiết bị đo (nếu có)
    
    -- THÔNG TIN GHI NHẬN
    --RecordedBy UNIQUEIDENTIFIER NULL,-- KTV ghi nhận
    RecordedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    
    -- ẢNH CHỤP 
    --ImageUrls NVARCHAR(1000) NULL,
    
    -- GHI CHÚ
    --Notes NVARCHAR(500) NULL,
    
    FOREIGN KEY (InspStageId) REFERENCES dbo.InspectionStage(InspStageId) ON DELETE CASCADE,
    FOREIGN KEY (ItemId) REFERENCES dbo.StageItem(ItemId),
    --FOREIGN KEY (RecordedBy) REFERENCES dbo.[User](UserId),
    CONSTRAINT UQ_InspDetail UNIQUE (InspStageId, ItemId)
);

ALTER TABLE dbo.InspectionDetail
ADD InspectionId INT NULL;
GO

-- alter table InspectionDetail
-- DROP COLUMN ActualText, DeviationPercent, DeviceId, ImageUrls, Notes, StandardText

-- 4.4) Bảng InspectionDefect (Danh sách lỗi phát hiện)
-- Ghi nhận các lỗi/hư hỏng phát hiện trong quá trình kiểm định
CREATE TABLE dbo.InspectionDefect (
    DefectId BIGINT IDENTITY(1,1) PRIMARY KEY,
    InspectionId INT NOT NULL,
    InspStageId BIGINT NULL,-- Lỗi phát hiện ở công đoạn nào
    ItemId INT NULL,-- Lỗi liên quan chỉ tiêu nào
    
    -- PHÂN LOẠI LỖI
    DefectCategory NVARCHAR(50) NOT NULL,-- Danh mục (VD: "Hệ thống phanh", "Hệ thống đèn")
    DefectCode NVARCHAR(40) NULL,-- Mã lỗi chuẩn (VD: "HTP", "HTD")
    
    -- MÔ TẢ LỖI
    DefectDescription NVARCHAR(1000) NOT NULL,          -- Mô tả chi tiết lỗi
    
    -- MỨC ĐỘ NGHIÊM TRỌNG
    Severity INT NOT NULL DEFAULT 2,
    /*
        1: KHUYẾT ĐIỂM - Nhắc nhở, không ảnh hưởng kết quả
        2: HƯ HỎNG - Không đạt, cần sửa chữa
        3: NGUY HIỂM - Nghiêm trọng, cấm lưu hành
    */
    
    -- HÌNH ẢNH MINH HỌA
    ImageUrls NVARCHAR(1000) NULL,
    
    -- TRẠNG THÁI XỬ LÝ (cho tái kiểm)
    IsFixed BIT NOT NULL DEFAULT 0,-- Đã sửa chữa?
    FixedNote NVARCHAR(500) NULL,-- Ghi chú về việc sửa chữa
    VerifiedBy UNIQUEIDENTIFIER NULL,-- KTV xác nhận đã sửa (tái kiểm)
    
    -- NGƯỜI PHÁT HIỆN
    --CreatedBy UNIQUEIDENTIFIER NULL,-- KTV phát hiện lỗi
    
    FOREIGN KEY (InspectionId) REFERENCES dbo.Inspection(InspectionId) ON DELETE CASCADE,
    FOREIGN KEY (InspStageId) REFERENCES dbo.InspectionStage(InspStageId),
    FOREIGN KEY (ItemId) REFERENCES dbo.StageItem(ItemId),
    --FOREIGN KEY (CreatedBy) REFERENCES dbo.[User](UserId),
    FOREIGN KEY (VerifiedBy) REFERENCES dbo.[User](UserId),
    CONSTRAINT CK_Defect_Severity CHECK (Severity BETWEEN 1 AND 3)
);

-- 5) NHÓM THU PHÍ - CHỨNG NHẬN - THIẾT KẾ LẠI

-- 5.1) Bảng FeeSchedule (Bảng giá dịch vụ)
-- Quản lý giá theo loại xe và loại kiểm định
CREATE TABLE dbo.FeeSchedule (
    FeeId INT IDENTITY(1,1) PRIMARY KEY,
    
    -- PHÂN LOẠI PHÍ
    ServiceType NVARCHAR(30) NOT NULL,
    /*
        FIRST_INSPECTION    - Kiểm định lần đầu
        PERIODIC           - Định kỳ
        RE_INSPECTION      - Tái kiểm
    */
    
    VehicleTypeId       INT NULL,-- Loại xe áp dụng hoăc tất cả xe
    
    -- GIÁ PHÍ
    BaseFee DECIMAL(18,2) NOT NULL,-- Phí cơ bản
    CertificateFee DECIMAL(18,2) DEFAULT 0,-- Phí giấy chứng nhận, tem  90.000
    StickerFee DECIMAL(18,2) DEFAULT 0,-- Phí lập hồ sơ 49.680 đồng đã bao gồm VAT 8%
    TotalFee DECIMAL(18,2) NOT NULL,-- Tổng phí
    
    -- THỜI GIAN ÁP DỤNG
    EffectiveFrom DATE NOT NULL,
    EffectiveTo DATE NULL,-- NULL = vô thời hạn
    
    -- TRẠNG THÁI
    IsActive BIT NOT NULL DEFAULT 1,
    
    CreatedBy UNIQUEIDENTIFIER NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UpdatedBy UNIQUEIDENTIFIER NULL,
    UpdatedAt DATETIME2 NULL,
    
    FOREIGN KEY (VehicleTypeId) REFERENCES dbo.VehicleType(VehicleTypeId),
    CONSTRAINT CK_Fee_Dates CHECK (EffectiveTo IS NULL OR EffectiveTo >= EffectiveFrom),
    CONSTRAINT CK_Fee_Amount CHECK (TotalFee >= 0)
);

-- 5.2) Bảng Payment (Thanh toán)
CREATE TABLE dbo.Payment (
    PaymentId INT IDENTITY(1,1) PRIMARY KEY,

    InspectionId INT NOT NULL,  
    -- CHI TIẾT PHÍ
    FeeScheduleId INT NULL,-- Tham chiếu bảng giá
    BaseFee DECIMAL(18,2) NOT NULL,-- Phí cơ bản
    CertificateFee DECIMAL(18,2) DEFAULT 0,
    StickerFee DECIMAL(18,2) DEFAULT 0,
    TotalAmount DECIMAL(18,2) NOT NULL, -- Tổng tiền
    
    -- PHƯƠNG THỨC THANH TOÁN
    PaymentMethod NVARCHAR(30) NOT NULL,
    /*
        - Tiền mặt
        - Chuyển khoản
    */
    
    -- TRẠNG THÁI THANH TOÁN
    PaymentStatus       SMALLINT NOT NULL DEFAULT 0,
    /*
        0: PENDING   - Chờ thanh toán
        1: PAID      - Đã thanh toán
        2: CANCELLED - Đã hủy
    */
    
    -- THÔNG TIN BIÊN NHẬN
    ReceiptNo NVARCHAR(40) NULL UNIQUE, -- Số biên nhận
    ReceiptPrintCount INT DEFAULT 0, -- Số lần in biên nhận

    -- THỜI GIAN
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    PaidAt DATETIME2 NULL, -- Thời điểm thanh toán
    -- NGƯỜI THỰC HIỆN
    CreatedBy UNIQUEIDENTIFIER NULL,  -- Thu ngân tạo phiếu
    PaidBy UNIQUEIDENTIFIER NULL,  -- Thu ngân nhận tiền
   
    
    -- GHI CHÚ
    Notes NVARCHAR(500) NULL,
   
    -- Cung cấp cho PayOS
	OrderCode BIGINT,
    
    FOREIGN KEY (InspectionId) REFERENCES dbo.Inspection(InspectionId) ON DELETE CASCADE,
    FOREIGN KEY (FeeScheduleId) REFERENCES dbo.FeeSchedule(FeeId),
    FOREIGN KEY (CreatedBy) REFERENCES dbo.[User](UserId),
    FOREIGN KEY (PaidBy) REFERENCES dbo.[User](UserId),
    CONSTRAINT CK_Payment_Status CHECK (PaymentStatus BETWEEN 0 AND 3),
    CONSTRAINT CK_Payment_Amount CHECK (TotalAmount >= 0),
    CONSTRAINT UQ_Payment_Inspection UNIQUE (InspectionId)  -- Mỗi hồ sơ 1 phiếu thu
);

-- 5.3) Bảng Certificate (Chứng nhận kiểm định)
-- Cấp cho xe ĐẠT kiểm định
CREATE TABLE dbo.Certificate (
    CertificateId       INT IDENTITY(1,1) PRIMARY KEY,
    InspectionId        INT NOT NULL,
    
    -- SỐ CHỨNG NHẬN
    CertificateNo NVARCHAR(40) NOT NULL UNIQUE, -- Số GCN (VD: 1234567890-01/2024)
    StickerNo NVARCHAR(40) NULL UNIQUE, -- Số tem kiểm định
    
    -- THỜI HẠN
    IssueDate DATE NOT NULL,-- Ngày cấp
    ExpiryDate DATE NOT NULL,-- Ngày hết hạn
    ValidityMonths INT NOT NULL DEFAULT 12,-- Số tháng có hiệu lực
    
    -- TRẠNG THÁI
    Status  SMALLINT NOT NULL DEFAULT 1,
    /*
        1: ACTIVE    - Còn hiệu lực
        2: EXPIRED   - Hết hạn
        3: REVOKED   - Thu hồi
        4: REPLACED  - Thay thế (cấp lại)
    */
    
    -- THÔNG TIN IN ẤN
    PrintTemplate       NVARCHAR(50) DEFAULT N'STANDARD', -- Template in
    PrintCount INT DEFAULT 0,  -- Số lần in
    LastPrintedAt DATETIME2 NULL, -- Lần in cuối
    
    -- THÔNG TIN CẤP PHÁT
    IssuedBy UNIQUEIDENTIFIER NULL,  -- Cán bộ cấp
    IssuedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    
    -- FILE ĐÍNH KÈM
    PdfUrl NVARCHAR(500) NULL,  -- File PDF chứng nhận
    
    -- GHI CHÚ
    Notes NVARCHAR(500) NULL,
    
    FOREIGN KEY (InspectionId) REFERENCES dbo.Inspection(InspectionId),
    FOREIGN KEY (IssuedBy) REFERENCES dbo.[User](UserId),
    CONSTRAINT CK_Certificate_Status CHECK (Status BETWEEN 1 AND 4),
    CONSTRAINT CK_Certificate_Dates CHECK (ExpiryDate > IssueDate),
    CONSTRAINT UQ_Certificate_Inspection UNIQUE (InspectionId)
);
  
-- THÔNG TIN KIỂM ĐỊNH
-- InspectionReportNo      NVARCHAR(50) NULL,             -- Số phiếu kiểm định
--IssuedDate              DATE NULL,                     -- Ngày cấp
--InspectionCenter        NVARCHAR(200) NULL,            -- Cơ sở đăng kiểm

ALTER TABLE dbo.Certificate 
ADD InspectionReportNo  NVARCHAR(50) NULL,					-- Số phiếu kiểm định
        IssuedDate DATE NULL,									-- Ngày cấp
        InspectionCenter   NVARCHAR(200) NULL;					-- Cơ sở đăng kiểm


-- =========================
-- BONUS: AUDIT LOG
-- =========================
CREATE TABLE dbo.AuditLog (
    AuditId     BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserId      UNIQUEIDENTIFIER NULL,
    Action      NVARCHAR(60) NOT NULL,     -- CREATE_INSPECTION, UPDATE_MEASUREMENT...
    Entity      NVARCHAR(60) NULL,
    EntityId    NVARCHAR(60) NULL,
    Detail      NVARCHAR(4000) NULL,
    CreatedAt   DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FOREIGN KEY (UserId) REFERENCES dbo.[User](UserId)
);

--Index
CREATE UNIQUE INDEX UX_Vehilce_Plateno
ON dbo.Vehicle (PlateNo) WHERE PlateNo IS NOT NULL;
GO

CREATE UNIQUE INDEX UX_Owner_Chassis 
ON dbo.Vehicle (Chassis ) WHERE Chassis  IS NOT NULL;
GO

-- MST chỉ unique với công ty
CREATE UNIQUE INDEX UX_Owner_TaxCode_Company
ON dbo.Owner(TaxCode)
WHERE OwnerType = N'COMPANY' AND TaxCode IS NOT NULL;
GO

CREATE UNIQUE INDEX UX_Owner_CCCD_Company
ON dbo.Owner(CCCD)
WHERE OwnerType = N'PERSON' AND CCCD IS NOT NULL;
GO

CREATE UNIQUE INDEX UX_Owner_Email
ON dbo.Owner(Email) WHERE Email IS NOT NULL;
GO

CREATE INDEX IX_Vehicle_PlateNo ON dbo.Vehicle(PlateNo);
CREATE INDEX IX_Vehicle_OwnerId ON dbo.Vehicle(OwnerId);
CREATE INDEX IX_Vehicle_InspectionNo ON dbo.Vehicle(InspectionNo);

CREATE INDEX IX_LaneStage_LaneId ON dbo.LaneStage(LaneId);

CREATE INDEX IX_Specification_PlateNo ON dbo.Specification(PlateNo);
CREATE INDEX IX_Specification_InspectionReportNo ON dbo.Specification(InspectionReportNo);
CREATE INDEX IX_Vehicle_OwnerId ON dbo.Vehicle(OwnerId);

CREATE INDEX IX_Inspection_VehicleId ON dbo.Inspection(VehicleId);
CREATE INDEX IX_Inspection_Status ON dbo.Inspection(Status) WHERE IsDeleted = 0;
CREATE INDEX IX_Inspection_ReceivedAt ON dbo.Inspection(ReceivedAt);
CREATE INDEX IX_Inspection_LaneId ON dbo.Inspection(LaneId) WHERE Status IN (3,4);
CREATE INDEX IX_Inspection_InspectionType ON dbo.Inspection(InspectionType);

CREATE INDEX IX_InspStage_InspectionId ON dbo.InspectionStage(InspectionId);
CREATE INDEX IX_InspStage_Status ON dbo.InspectionStage(Status);
CREATE INDEX IX_InspStage_AssignedUserId ON dbo.InspectionStage(AssignedUserId) WHERE Status IN (0,1);

CREATE INDEX IX_InspDetail_InspStageId ON dbo.InspectionDetail(InspStageId);
CREATE INDEX IX_InspDetail_IsPassed ON dbo.InspectionDetail(IsPassed) WHERE IsPassed = 0;

CREATE INDEX IX_Defect_InspectionId ON dbo.InspectionDefect(InspectionId);
CREATE INDEX IX_Defect_Severity ON dbo.InspectionDefect(Severity);
CREATE INDEX IX_Defect_IsFixed ON dbo.InspectionDefect(IsFixed) WHERE Severity >= 2;

CREATE INDEX IX_Payment_Status ON dbo.Payment(PaymentStatus); 
CREATE INDEX IX_Payment_PaidAt ON dbo.Payment(PaidAt);
CREATE INDEX IX_Payment_ReceiptNo ON dbo.Payment(ReceiptNo);

CREATE INDEX IX_Certificate_Status ON dbo.Certificate(Status);
CREATE INDEX IX_Certificate_ExpiryDate ON dbo.Certificate(ExpiryDate) WHERE Status = 1;
CREATE INDEX IX_Certificate_IssueDate ON dbo.Certificate(IssueDate);

CREATE INDEX IX_FeeSchedule_ServiceType ON dbo.FeeSchedule(ServiceType);
CREATE INDEX IX_FeeSchedule_Effective ON dbo.FeeSchedule(EffectiveFrom, EffectiveTo) WHERE IsActive = 1;

--========================
-- TRIGGERS
GO
CREATE OR ALTER TRIGGER dbo.trg_FeeSchedule_CalcTotalFee
ON dbo.FeeSchedule
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ cập nhật những row vừa bị tác động
    UPDATE fs
    SET fs.TotalFee =
        fs.BaseFee
      + ISNULL(fs.CertificateFee, 0)
      + ISNULL(fs.StickerFee, 0)
    FROM dbo.FeeSchedule fs
    JOIN inserted i ON i.FeeId = fs.FeeId;
END
GO

GO
CREATE OR ALTER TRIGGER dbo.trg_Inspection_AfterInsert_CreatePayment
ON dbo.Inspection
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) Gom dữ liệu nguồn: Inspection + VehicleTypeId + ServiceType
    DECLARE @src TABLE
    (
        InspectionId INT PRIMARY KEY,
        CreatedAt    DATETIME2 NOT NULL,
        CreatedBy    UNIQUEIDENTIFIER NULL,
        VehicleTypeId INT NULL,
        ServiceType  NVARCHAR(30) NULL
    );

    INSERT INTO @src (InspectionId, CreatedAt, CreatedBy, VehicleTypeId, ServiceType)
    SELECT
        i.InspectionId,
        i.CreatedAt,
        i.CreatedBy,
        v.VehicleTypeId,
        CASE i.InspectionType
            WHEN N'FIRST'         THEN N'FIRST'
            WHEN N'PERIODIC'      THEN N'PERIODIC'
            WHEN N'RE_INSPECTION' THEN N'RE_INSPECTION'
            ELSE NULL
        END AS ServiceType
    FROM inserted i
    JOIN dbo.Vehicle v ON v.VehicleId = i.VehicleId;

    -- 2) Chọn FeeSchedule phù hợp (mỗi Inspection lấy 1 dòng tốt nhất)
    DECLARE @pick TABLE
    (
        InspectionId INT PRIMARY KEY,
        FeeId INT NOT NULL,
        BaseFee DECIMAL(18,2) NOT NULL,
        CertificateFee DECIMAL(18,2) NOT NULL,
        StickerFee DECIMAL(18,2) NOT NULL,
        TotalFee DECIMAL(18,2) NOT NULL
    );

    INSERT INTO @pick (InspectionId, FeeId, BaseFee, CertificateFee, StickerFee, TotalFee)
    SELECT
        s.InspectionId,
        fs.FeeId,
        fs.BaseFee,
        ISNULL(fs.CertificateFee, 0),
        ISNULL(fs.StickerFee, 0),
        fs.TotalFee
    FROM @src s
    CROSS APPLY
    (
        SELECT TOP (1) fs.*
        FROM dbo.FeeSchedule fs
        WHERE fs.IsActive = 1
          AND fs.ServiceType = s.ServiceType
          AND (fs.VehicleTypeId = s.VehicleTypeId OR fs.VehicleTypeId IS NULL)
          AND CONVERT(date, s.CreatedAt) >= fs.EffectiveFrom
          AND (fs.EffectiveTo IS NULL OR CONVERT(date, s.CreatedAt) <= fs.EffectiveTo)
        ORDER BY
          CASE WHEN fs.VehicleTypeId = s.VehicleTypeId THEN 0 ELSE 1 END,
          fs.EffectiveFrom DESC,
          fs.FeeId DESC
    ) fs
    WHERE s.ServiceType IS NOT NULL;

    -- 3) Nếu có Inspection nào không pick được bảng giá -> rollback rõ ràng
    IF EXISTS (
        SELECT 1
        FROM @src s
        LEFT JOIN @pick p ON p.InspectionId = s.InspectionId
        WHERE p.InspectionId IS NULL
    )
    BEGIN
        THROW 50001, N'Không tìm thấy FeeSchedule hợp lệ cho Inspection vừa tạo (ServiceType/VehicleTypeId/EffectiveFrom/EffectiveTo/IsActive).', 1;
    END;

    -- 4) Insert Payment (copy phí từ FeeSchedule)
    INSERT INTO dbo.Payment
    (
        InspectionId,
        FeeScheduleId,
        BaseFee,
        CertificateFee,
        StickerFee,
        TotalAmount,
        PaymentMethod,
        PaymentStatus,
        ReceiptNo,
        ReceiptPrintCount,
        CreatedAt,
        PaidAt,
        CreatedBy,
        PaidBy,
        Notes
    )
    SELECT
        s.InspectionId,
        p.FeeId,
        p.BaseFee,
        p.CertificateFee,
        p.StickerFee,
        p.TotalFee,
        N'Chưa xác định',
        0,                 -- PENDING
        CONCAT(
        N'RC-',
        FORMAT(SYSDATETIME(), 'yyyyMMddHHmmssfff'),
        N'-',
        RIGHT(CONCAT('000000', CAST(s.InspectionId AS varchar(10))), 6)
		) AS ReceiptNo,
        0,
        SYSDATETIME(),
        NULL,
        s.CreatedBy,
        NULL,
        NULL
    FROM @src s
    JOIN @pick p ON p.InspectionId = s.InspectionId
    LEFT JOIN dbo.Payment pay ON pay.InspectionId = s.InspectionId
    WHERE pay.InspectionId IS NULL;
END
GO


EXEC sp_helpindex 'dbo.Payment';


INSERT INTO Role(RoleCode, RoleAcronym, RoleName, RoleIcon, RoleHref)
VALUES ('LOGIN', N'Đăng nhập', N'Đăng nhập hệ thống', 'fa-solid fa-arrow-right-to-bracket', ''),
	   ('EMPLOYEE', N'Nhân sự', N'Quản lý nhân sự', 'fa-regular fa-address-book', 'employee'),
	   ('RECEIVE PROFILE', N'Hồ sơ', N'Tiếp nhận hồ sơ', 'fa-regular fa-address-card', 'receive-profile'),
	   ('INSPECTION', N'Kiểm định', N'Tạo lượt kiểm định', 'fa-solid fa-magnifying-glass', 'inspection'),
	   ('TOLL', N'Thu phí', N'Thu phí, in biên nhận', 'fa-solid fa-coins', 'toll'),
	   ('RESULT', N'Kết quả', N'Nhập kết quả kiểm định theo công đoạn', 'fa-regular fa-pen-to-square', 'result'),
	   ('CONCLUSION', N'Kết luận', N'Chốt kết luận đạt/không đạt', 'fa-regular fa-handshake', 'conclusion'),
	   ('REPORT', N'Xem báo cáo', N'Xem báo cáo', 'fa-solid fa-chart-pie', 'report')

INSERT INTO dbo.Position (PoitionCode, PositionName)
VALUES  
		('BV',   N'Bảo vệ / an ninh'),	
		('CSKH', N'Lễ tân / CSKH'),
		('GSV',  N'Giám sát viên'),
		('TTDC', N'Tổ trưởng dây chuyền'),
		('KTV',  N'Kỹ thuật viên'),
		('HS',   N'Nhân viên hồ sơ'),
		('TN',   N'Thu ngân'),
		('KT',   N'Kế toán'),
		('TB',   N'Nhân viên thiết bị'),
		('IT',   N'Quản trị hệ thống'),
		('GD',   N'Giám đốc'),
		('PGD',  N'Phó Giám đốc');
		
INSERT INTO dbo.Team (TeamCode, TeamName)
VALUES
	('AN',   N'Tổ an ninh'),
	('DC1',  N'Dây chuyền 1 - Xe con & Bán tải'),
	('DC2',  N'Dây chuyền 2 - Xe khách & Xe buýt'),
	('HS',   N'Tổ hồ sơ - tiếp nhận'),
	('TC',   N'Tổ thu ngân'),
	('KT',   N'Tổ kế toán - tài chính'),
	('TBHC', N'Tổ thiết bị - hiệu chuẩn'),
	('IT',   N'Tổ CNTT'),
	('BGD',  N'Ban giám đốc');

INSERT INTO dbo.Team (TeamCode, TeamName)
VALUES
	('DC3',  N'Dây chuyền 3 - Xe tải'),
	('DC4',  N'Dây chuyền 4 - Xe đầu kéo & Rơ moóc'),
	('DC5',  N'Dây chuyền 5 - Xe mô tô & 3 bánh'),
	('DC6',  N'Dây chuyền 6 - Xe chuyên dùng')

INSERT INTO PositionTeam (PositionId, TeamId)
SELECT P.PositionId, T.TeamId
FROM Position P
JOIN Team T ON T.TeamCode IN ('DC1','DC2','DC3','DC4','DC5','DC6')
WHERE P.PoitionCode IN ('KTV','GSV','TTDC');

INSERT INTO PositionTeam (PositionId, TeamId)
SELECT P.PositionId, T.TeamId
FROM Position P
JOIN Team T ON T.TeamCode = 'AN'
WHERE P.PoitionCode = 'BV';

INSERT INTO PositionTeam (PositionId, TeamId)
SELECT P.PositionId, T.TeamId
FROM Position P
JOIN Team T ON T.TeamCode = 'HS'
WHERE P.PoitionCode IN ('CSKH','HS');

INSERT INTO PositionTeam (PositionId, TeamId)
SELECT P.PositionId, T.TeamId
FROM Position P
JOIN Team T ON T.TeamCode = 'TC'
WHERE P.PoitionCode = 'TN';

INSERT INTO PositionTeam (PositionId, TeamId)
SELECT P.PositionId, T.TeamId
FROM Position P
JOIN Team T ON T.TeamCode = 'KT'
WHERE P.PoitionCode = 'KT';

INSERT INTO PositionTeam (PositionId, TeamId)
SELECT P.PositionId, T.TeamId
FROM Position P
JOIN Team T ON T.TeamCode = 'TBHC'
WHERE P.PoitionCode = 'TB';

INSERT INTO PositionTeam (PositionId, TeamId)
SELECT P.PositionId, T.TeamId
FROM Position P
JOIN Team T ON T.TeamCode = 'IT'
WHERE P.PoitionCode = 'IT';

INSERT INTO PositionTeam (PositionId, TeamId)
SELECT P.PositionId, T.TeamId
FROM Position P
JOIN Team T ON T.TeamCode = 'BGD'
WHERE P.PoitionCode IN ('GD','PGD');


--- Lấy ID thực tế của thằng này nhé !!!
INSERT INTO Account(UserId, Username, PasswordHash)
VALUES ('12e1e67c-117b-41fb-905d-21adc807c299', 'PhanMinh', 'PhanMinh@123')



-- Insert Owner
INSERT INTO dbo.Owner (OwnerId, OwnerType, FullName, CompanyName, TaxCode, CCCD, Phone, Email, Address, Ward, Province) VALUES 
(NEWID(), N'PERSON', N'Nguyễn Văn An', NULL, NULL, N'079123456789', N'0901234567', N'nguyenvanan@email.com', N'123 Đường Lê Lợi, Quận 1', N'Phường Bến Nghé', N'TP.HCM');

-- Insert Vehicle
DECLARE @OwnerId UNIQUEIDENTIFIER; 
SELECT TOP 1 @OwnerId = OwnerId FROM dbo.Owner; 
INSERT INTO dbo.Vehicle (PlateNo, InspectionNo, VehicleGroup, VehicleType, EnergyType, IsCleanEnergy, UsagePermission, Brand, Model, EngineNo, Chassis, ManufactureYear, ManufactureCountry, LifetimeLimitYear, HasCommercialModification, HasModification, OwnerId) VALUES 
(N'51A-12345', N'VN-2024-123456', N'Ô tô con', N'Sedan', N'Xăng', 0, N'Không', N'Toyota', N'Vios 1.5E CVT', N'2NR-FE-1234567', N'MH123456789012345', 2023, N'Việt Nam', NULL, 0, 0, @OwnerId);

-- Insert Specification
INSERT INTO dbo.Specification (PlateNo, WheelFormula, WheelTread, OverallLength, OverallWidth, OverallHeight, CargoInsideLength, CargoInsideWidth, CargoInsideHeight, Wheelbase, 
KerbWeight, AuthorizedCargoWeight, AuthorizedTowedWeight, AuthorizedTotalWeight, SeatingCapacity, StandingCapacity, LyingCapacity, EngineType, EnginePosition, EngineModel, EngineDisplacement, MaxPower, MaxPowerRPM, FuelType, MotorType, NumberOfMotors, MotorModel, TotalMotorPower, MotorVoltage, BatteryType, BatteryVoltage, BatteryCapacity, TireCount, TireSize, TireAxleInfo, ImagePosition, HasTachograph, HasDriverCamera, NotIssuedStamp, Notes) 
VALUES (N'51A-12345', N'4x2', 1510, 4425, 1730, 1475, NULL, NULL, NULL, 2550, 1075.00, 400.00, 0.00, 1695.00, 5, 0, 0, N'Xăng 4 kỳ', N'Trước ngang', N'2NR-FE', 1496, 79.00, 6000, N'Xăng RON 95', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, N'185/60R15', N'Trục 1: 185/60R15, Trục 2: 185/60R15', NULL, 0, 1, 0, N'Xe gia đình, bảo dưỡng định kỳ');

-- 1. INSERT Owner
INSERT INTO dbo.Owner (OwnerId, OwnerType, FullName, CompanyName, TaxCode, CCCD, Phone, Email, Address, Ward, Province, ImageUrl) VALUES 
(NEWID(), N'PERSON', N'Nguyễn Văn An', NULL, NULL, N'001234567890', N'0912345678', N'nguyenvanan@email.com', N'123 Đường Lê Lợi', N'Phường Bến Nghé', N'TP Hồ Chí Minh', NULL);

-- Lấy OwnerId vừa tạo
DECLARE @OwnerId UNIQUEIDENTIFIER = (SELECT TOP 1 OwnerId FROM dbo.Owner ORDER BY CreatedAt DESC);

-- 2. INSERT Vehicle
INSERT INTO dbo.Vehicle (PlateNo, InspectionNo, VehicleGroup, VehicleType, EnergyType, IsCleanEnergy, UsagePermission, Brand, Model, EngineNo, Chassis, ManufactureYear, ManufactureCountry, LifetimeLimitYear, HasCommercialModification, HasModification, OwnerId) VALUES 
(N'51A-12245', N'VN-HCM-2024-001234', N'Xe con', N'Sedan', N'Xăng', 0, N'Không', N'Toyota', N'Vios 1.5E MT', N'3NR-FE-1234567', N'VNKKG5E18P0123456', 2023, N'Việt Nam', 2043, 0, 0, @OwnerId);

-- 3. INSERT Specification
INSERT INTO dbo.Specification (PlateNo, WheelFormula, WheelTread, OverallLength, OverallWidth, OverallHeight, CargoInsideLength, CargoInsideWidth, CargoInsideHeight, Wheelbase, KerbWeight, AuthorizedCargoWeight, AuthorizedTowedWeight, AuthorizedTotalWeight, SeatingCapacity, 
StandingCapacity, LyingCapacity, EngineType, EnginePosition, EngineModel, EngineDisplacement, MaxPower, MaxPowerRPM, FuelType, MotorType, NumberOfMotors, MotorModel, TotalMotorPower, MotorVoltage, BatteryType, BatteryVoltage, BatteryCapacity, TireCount, TireSize, TireAxleInfo, ImagePosition, HasTachograph, HasDriverCamera, NotIssuedStamp, Notes) VALUES 
(N'51A-12245', N'4x2', 1460, 4425, 1730, 1475, NULL, NULL, NULL, 2550, 1025.00, 450.00, 0.00, 1650.00, 5, 0, 0, N'Xăng 4 kỳ, 4 xi-lanh thẳng hàng', N'Phía trước', N'3NR-FE', 1496, 79.00, 6000, N'Xăng RON 95', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, N'185/60R15', N'Trục trước: 185/60R15; Trục sau: 185/60R15', N'Góc trên bên phải kính lái', 0, 0, 0, N'Xe đăng ký lần đầu, tình trạng tốt');


INSERT INTO dbo.Owner (OwnerId, OwnerType, FullName, CompanyName, TaxCode, CCCD, Phone, Email, Address, Ward, Province, ImageUrl)
VALUES
    -- Chủ xe cá nhân (6 bản ghi)
    (NEWID(), N'PERSON', N'Nguyễn Văn An', NULL, NULL, N'001244567890', N'0901234567', N'nguyenvanan@gmail.com', N'123 Lê Lợi, Quận 1', N'Phường Bến Nghé', N'TP. Hồ Chí Minh', N'https://example.com/images/owner1.jpg'),
    
    (NEWID(), N'PERSON', N'Trần Thị Bình', NULL, NULL, N'001234567891', N'0912345678', N'tranthibinh@gmail.com', N'456 Nguyễn Huệ, Quận 1', N'Phường Bến Thành', N'TP. Hồ Chí Minh', N'https://example.com/images/owner2.jpg'),
    
    (NEWID(), N'PERSON', N'Lê Hoàng Cường', NULL, NULL, N'001234567892', N'0923456789', N'lehoangcuong@gmail.com', N'789 Hai Bà Trưng, Quận 1', N'Phường Đa Kao', N'TP. Hồ Chí Minh', NULL),
    
    (NEWID(), N'PERSON', N'Phạm Minh Đức', NULL, NULL, N'001234567893', N'0934567890', N'phamminhduc@gmail.com', N'321 Trần Hưng Đạo, Quận 1', N'Phường Cầu Kho', N'TP. Hồ Chí Minh', N'https://example.com/images/owner4.jpg'),
    
    (NEWID(), N'PERSON', N'Võ Thị Em', NULL, NULL, N'001234567894', N'0945678901', N'vothiem@gmail.com', N'654 Điện Biên Phủ, Quận 3', N'Phường 25', N'TP. Hồ Chí Minh', NULL),
    
    (NEWID(), N'PERSON', N'Hoàng Văn Phong', NULL, NULL, N'001234567895', N'0956789012', N'hoangvanphong@gmail.com', N'987 Cách Mạng Tháng 8, Quận 10', N'Phường 7', N'TP. Hồ Chí Minh', N'https://example.com/images/owner6.jpg'),
    
    -- Chủ xe công ty (4 bản ghi)
    (NEWID(), N'COMPANY', N'Nguyễn Văn Giang', N'Công ty TNHH Vận Tải Sài Gòn', N'0123456789', N'001334567895', N'0967890123', N'contact@vantaisaigon.vn', N'100 Nguyễn Thị Minh Khai, Quận 3', N'Phường Võ Thị Sáu', N'TP. Hồ Chí Minh', N'https://example.com/images/company1.jpg'),
    
    (NEWID(), N'COMPANY', N'Trần Thị Hương', N'Công ty Cổ Phần Xe Khách Phương Trang', N'0234567890', N'001244567895', N'0978901234', N'info@phuongtrang.vn', N'272 Đề Thám, Quận 1', N'Phường Phạm Ngũ Lão', N'TP. Hồ Chí Minh', N'https://example.com/images/company2.jpg'),
    
    (NEWID(), N'COMPANY', N'Lê Minh Tuấn', N'Công ty TNHH Logistic Việt Nam', N'0345678901', N'001235567895', N'0989012345', N'contact@logisticvn.com', N'300 Võ Văn Tần, Quận 3', N'Phường 5', N'TP. Hồ Chí Minh', NULL),
    
    (NEWID(), N'COMPANY', N'Phạm Thị Lan', N'Công ty TNHH MTV Vận Tải Miền Đông', N'0456789012', N'0012345667895', N'0990123456', N'info@vantaimiendong.vn', N'400 Hoàng Sa, Quận 1', N'Phường Đa Kao', N'TP. Hồ Chí Minh', N'https://example.com/images/company4.jpg');

GO

-- =============================================
-- 2. DỮ LIỆU BẢNG VEHICLE (10 bản ghi)
-- Sử dụng VehicleTypeId: 9, 10, 11, 12, 13, 14, 15, 16, 17, 21
-- =============================================

DECLARE @Owner1 UNIQUEIDENTIFIER = (SELECT TOP 1 OwnerId FROM dbo.Owner WHERE FullName = N'Nguyễn Văn An' ORDER BY CreatedAt DESC);
DECLARE @Owner2 UNIQUEIDENTIFIER = (SELECT TOP 1 OwnerId FROM dbo.Owner WHERE FullName = N'Trần Thị Bình' ORDER BY CreatedAt DESC);
DECLARE @Owner3 UNIQUEIDENTIFIER = (SELECT TOP 1 OwnerId FROM dbo.Owner WHERE FullName = N'Lê Hoàng Cường' ORDER BY CreatedAt DESC);
DECLARE @Owner4 UNIQUEIDENTIFIER = (SELECT TOP 1 OwnerId FROM dbo.Owner WHERE FullName = N'Phạm Minh Đức' ORDER BY CreatedAt DESC);
DECLARE @Owner5 UNIQUEIDENTIFIER = (SELECT TOP 1 OwnerId FROM dbo.Owner WHERE FullName = N'Võ Thị Em' ORDER BY CreatedAt DESC);
DECLARE @Owner6 UNIQUEIDENTIFIER = (SELECT TOP 1 OwnerId FROM dbo.Owner WHERE FullName = N'Hoàng Văn Phong' ORDER BY CreatedAt DESC);
DECLARE @Owner7 UNIQUEIDENTIFIER = (SELECT TOP 1 OwnerId FROM dbo.Owner WHERE CompanyName = N'Công ty TNHH Vận Tải Sài Gòn' ORDER BY CreatedAt DESC);
DECLARE @Owner8 UNIQUEIDENTIFIER = (SELECT TOP 1 OwnerId FROM dbo.Owner WHERE CompanyName = N'Công ty Cổ Phần Xe Khách Phương Trang' ORDER BY CreatedAt DESC);
DECLARE @Owner9 UNIQUEIDENTIFIER = (SELECT TOP 1 OwnerId FROM dbo.Owner WHERE CompanyName = N'Công ty TNHH Logistic Việt Nam' ORDER BY CreatedAt DESC);
DECLARE @Owner10 UNIQUEIDENTIFIER = (SELECT TOP 1 OwnerId FROM dbo.Owner WHERE CompanyName = N'Công ty TNHH MTV Vận Tải Miền Đông' ORDER BY CreatedAt DESC);

INSERT INTO dbo.Vehicle (
    PlateNo, InspectionNo, VehicleGroup, VehicleTypeId, 
    EnergyType, IsCleanEnergy, UsagePermission, 
    Brand, Model, EngineNo, Chassis, 
    ManufactureYear, ManufactureCountry, LifetimeLimitYear, 
    HasCommercialModification, HasModification, OwnerId
)
VALUES
    -- 1. Xe con Toyota (VehicleTypeId = 9: PAX_LT_10)
    (N'51A-12347', N'VN-HCM-2024-001234', N'Xe con', 9, 
     N'Xăng', 0, N'Không', 
     N'Toyota', N'Vios 1.5E CVT', N'2NR1234567', N'VNKKK1234ABC56789', 
     2022, N'Việt Nam', 2042, 
     0, 0, @Owner1),
    
    -- 2. Xe cứu thương Ford (VehicleTypeId = 10: AMBULANCE)
    (N'51B-23456', N'VN-HCM-2024-002345', N'Xe cứu thương', 10, 
     N'Dầu diesel', 0, N'Không', 
     N'Ford', N'Transit Ambulance', N'P8FA2345678', N'WF0XXXTTGFKE12345', 
     2023, N'Thái Lan', 2043, 
     1, 0, @Owner2),
    
    -- 3. Xe khách 16 chỗ Hyundai (VehicleTypeId = 11: PAX_10_24)
    (N'51C-34567', N'VN-HCM-2024-003456', N'Xe khách', 11, 
     N'Dầu diesel', 0, N'Không', 
     N'Hyundai', N'County', N'D4GA3456789', N'KMJHC41CBPU123456', 
     2021, N'Hàn Quốc', 2041, 
     1, 0, @Owner3),
    
    -- 4. Xe tải nhẹ Isuzu 1.9T (VehicleTypeId = 12: TRUCK_LT_2T)
    (N'51D-45678', N'VN-HCM-2024-004567', N'Xe tải nhẹ', 12, 
     N'Dầu diesel', 0, N'Không', 
     N'Isuzu', N'QKR77FE4', N'4JH14567890', N'MRALQKR1JK0123456', 
     2022, N'Việt Nam', 2042, 
     1, 0, @Owner4),
    
    -- 5. Xe khách 29 chỗ Thaco (VehicleTypeId = 13: PAX_25_40)
    (N'51E-56789', N'VN-HCM-2024-005678', N'Xe khách', 13, 
     N'Dầu diesel', 0, N'Không', 
     N'Thaco', N'TB85S', N'WP105678901', N'LZYTBKMB5JA123456', 
     2023, N'Việt Nam', 2043, 
     1, 0, @Owner5),
    
    -- 6. Xe tải Hino 5 tấn (VehicleTypeId = 14: TRUCK_2_7T)
    (N'51F-67890', N'VN-HCM-2024-006789', N'Xe tải trung', 14, 
     N'Dầu diesel', 0, N'Không', 
     N'Hino', N'FC9JLSW', N'J08E6789012', N'LHHFC8JR8MK123456', 
     2022, N'Nhật Bản', 2042, 
     1, 0, @Owner6),
    
    -- 7. Xe khách 47 chỗ Thaco (VehicleTypeId = 15: PAX_GT_40)
    (N'51G-78901', N'VN-HCM-2024-007890', N'Xe khách cao cấp', 15, 
     N'Dầu diesel', 0, N'Một phần', 
     N'Thaco', N'TB120SL', N'WP127890123', N'LZYTBKMB8KA234567', 
     2024, N'Việt Nam', 2044, 
     1, 0, @Owner7),
    
    -- 8. Xe buýt Hyundai (VehicleTypeId = 16: BUS)
    (N'51H-89012', N'VN-HCM-2024-008901', N'Xe buýt', 16, 
     N'CNG', 1, N'Không', 
     N'Hyundai', N'Universe', N'D6CC8901234', N'KMJHM45CBRU234567', 
     2023, N'Hàn Quốc', 2043, 
     1, 0, @Owner8),
    
    -- 9. Xe tải Dongfeng 15 tấn (VehicleTypeId = 17: TRUCK_7_20T)
    (N'51K-90123', N'VN-HCM-2024-009012', N'Xe tải nặng', 17, 
     N'Dầu diesel', 0, N'Không', 
     N'Dongfeng', N'Hoàng Huy L315', N'YC6L9012345', N'LGDFL5RM5LA345678', 
     2022, N'Trung Quốc', 2042, 
     1, 0, @Owner9),
    
    -- 10. Máy kéo FAW (VehicleTypeId = 21: TRACTOR)
    (N'51L-01234', N'VN-HCM-2024-010123', N'Máy kéo đầu', 21, 
     N'Dầu diesel', 0, N'Không', 
     N'FAW', N'J6P 430HP', N'CA6DM30123456', N'LFNAKPCH5MBE56789', 
     2023, N'Trung Quốc', 2043, 
     1, 0, @Owner10);

GO

-- =============================================
-- 3. DỮ LIỆU BẢNG SPECIFICATION (10 bản ghi)
-- =============================================

INSERT INTO dbo.Specification (
    PlateNo, WheelFormula, WheelTread, 
    OverallLength, OverallWidth, OverallHeight,
    CargoInsideLength, CargoInsideWidth, CargoInsideHeight, 
    Wheelbase, KerbWeight, AuthorizedCargoWeight, AuthorizedTowedWeight, AuthorizedTotalWeight,
    SeatingCapacity, StandingCapacity, LyingCapacity,
    EngineType, EnginePosition, EngineModel, EngineDisplacement, MaxPower, MaxPowerRPM, FuelType,
    MotorType, NumberOfMotors, MotorModel, TotalMotorPower, MotorVoltage,
    BatteryType, BatteryVoltage, BatteryCapacity,
    TireCount, TireSize, TireAxleInfo,
    ImagePosition, HasTachograph, HasDriverCamera, NotIssuedStamp, Notes
)
VALUES
    -- 1. Toyota Vios (Xe con 5 chỗ - 51A-12345)
    (N'51A-12347', N'4x2', 1540, 
     4425, 1730, 1475, NULL, NULL, NULL, 
     2550, 1075.00, 425.00, 0.00, 1500.00,
     5, 0, 0,
     N'Xăng, 4 kỳ', N'Trước dọc', N'2NR-FE', 1496, 79.00, 6000, N'Xăng RON 95',
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
     4, N'185/60 R15', N'Trục 1: 2 lốp, Trục 2: 2 lốp',
     N'Dashboard', 0, 0, 0, N'Xe gia đình, sử dụng cá nhân'),
    
    -- 2. Ford Transit Ambulance (Xe cứu thương - 51B-23456)
    (N'51B-23456', N'4x2', 1830, 
     5981, 2474, 2720, 3300, 1700, 1800, 
     3750, 2350.00, 1150.00, 0.00, 3500.00,
     3, 0, 2,
     N'Dầu, 4 kỳ, tăng áp', N'Trước dọc', N'P8FA (Puma)', 2198, 92.00, 3500, N'Dầu diesel',
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
     6, N'215/75 R16C', N'Trục 1: 2 lốp, Trục 2: 4 lốp',
     N'Dashboard', 1, 1, 0, N'Xe cứu thương bệnh viện, có trang bị y tế đầy đủ'),
    
    -- 3. Hyundai County (Xe khách 16 chỗ - 51C-34567)
    (N'51C-34567', N'4x2', 1815, 
     6995, 2385, 2960, NULL, NULL, NULL, 
     3930, 3480.00, 1520.00, 0.00, 5000.00,
     16, 0, 0,
     N'Dầu, 4 kỳ, tăng áp', N'Trước dọc', N'D4GA', 3933, 110.00, 2800, N'Dầu diesel',
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
     6, N'225/70 R19.5', N'Trục 1: 2 lốp, Trục 2: 4 lốp',
     N'Dashboard', 1, 1, 0, N'Xe khách vận chuyển hành khách liên tỉnh'),
    
    -- 4. Isuzu QKR (Xe tải nhẹ 1.9 tấn - 51D-45678)
    (N'51D-45678', N'4x2', 1610, 
     5995, 1995, 2240, 4200, 1850, 450, 
     3815, 2275.00, 1925.00, 0.00, 4200.00,
     3, 0, 0,
     N'Dầu, 4 kỳ, tăng áp', N'Trước dọc', N'4JH1-TC', 2999, 96.00, 3000, N'Dầu diesel',
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
     6, N'195/70 R15C', N'Trục 1: 2 lốp, Trục 2: 4 lốp',
     N'Dashboard', 1, 1, 0, N'Xe tải nhẹ chở hàng nội thành'),
    
    -- 5. Thaco TB85S (Xe khách 29 chỗ - 51E-56789)
    (N'51E-56789', N'4x2', 1970, 
     8470, 2420, 3280, NULL, NULL, NULL, 
     4700, 4950.00, 2550.00, 0.00, 7500.00,
     29, 0, 0,
     N'Dầu, 6 xy-lanh, tăng áp', N'Sau dọc', N'WP10.336E32', 9726, 247.00, 2200, N'Dầu diesel',
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
     6, N'9.00-20', N'Trục 1: 2 lốp, Trục 2: 4 lốp',
     N'Dashboard', 1, 1, 0, N'Xe khách du lịch, có tivi và điều hòa'),
    
    -- 6. Hino FC9JLSW (Xe tải 5 tấn - 51F-67890)
    (N'51F-67890', N'4x2', 1860, 
     7385, 2390, 2850, 5200, 2200, 600, 
     4800, 4150.00, 4850.00, 0.00, 9000.00,
     3, 0, 0,
     N'Dầu, 4 kỳ, tăng áp trung gian', N'Trước dọc', N'J08E-WU', 7684, 176.00, 2500, N'Dầu diesel',
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
     6, N'8.25-16', N'Trục 1: 2 lốp, Trục 2: 4 lốp',
     N'Dashboard', 1, 1, 0, N'Xe tải trung chở hàng đường dài'),
    
    -- 7. Thaco TB120SL (Xe khách 47 chỗ - 51G-78901)
    (N'51G-78901', N'4x2', 2040, 
     12000, 2500, 3650, NULL, NULL, NULL, 
     6100, 9800.00, 4200.00, 0.00, 14000.00,
     47, 0, 0,
     N'Dầu, 6 xy-lanh thẳng hàng, tăng áp', N'Sau dọc', N'WP12.430E32', 11596, 316.00, 1900, N'Dầu diesel',
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
     6, N'11.00R22.5', N'Trục 1: 2 lốp, Trục 2: 4 lốp',
     N'Dashboard', 1, 1, 0, N'Xe khách giường nằm cao cấp, có wifi và ổ cắm điện'),
    
    -- 8. Hyundai Universe (Xe buýt - 51H-89012)
    (N'51H-89012', N'4x2', 2100, 
     11990, 2490, 3580, NULL, NULL, NULL, 
     6040, 11200.00, 4800.00, 0.00, 16000.00,
     43, 30, 0,
     N'CNG, 6 xy-lanh, tăng áp', N'Sau ngang', N'D6CC', 11149, 294.00, 1900, N'Khí thiên nhiên nén (CNG)',
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
     6, N'275/70 R22.5', N'Trục 1: 2 lốp, Trục 2: 4 lốp',
     N'Dashboard', 1, 1, 0, N'Xe buýt BRT, thân thiện môi trường'),
    
    -- 9. Dongfeng L315 (Xe tải 15 tấn - 51K-90123)
    (N'51K-90123', N'6x4', 1820, 
     9480, 2500, 3200, 7600, 2350, 800, 
     4600, 8750.00, 15250.00, 0.00, 24000.00,
     3, 0, 0,
     N'Dầu, 6 xy-lanh thẳng hàng, tăng áp', N'Trước dọc', N'YC6L310-50', 8424, 228.00, 2100, N'Dầu diesel',
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
     10, N'10.00R20', N'Trục 1: 2 lốp, Trục 2: 4 lốp, Trục 3: 4 lốp',
     N'Dashboard', 1, 1, 0, N'Xe tải nặng chở hàng container'),
    
    -- 10. FAW J6P (Máy kéo đầu - 51L-01234)
    (N'51L-01234', N'6x4', 1850, 
     7220, 2550, 3150, NULL, NULL, NULL, 
     3650, 8900.00, 0.00, 40000.00, 48900.00,
     2, 0, 0,
     N'Dầu, 6 xy-lanh thẳng hàng, tăng áp trung gian', N'Trước dọc', N'CA6DM3-46E62', 11980, 316.00, 1900, N'Dầu diesel',
     NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
     10, N'12.00R22.5', N'Trục 1: 2 lốp, Trục 2: 4 lốp, Trục 3: 4 lốp',
     N'Dashboard', 1, 1, 0, N'Đầu kéo container 40 feet, phù hợp đường dài');

GO


DROP TABLE Specification
DROP TABLE Vehicle
DROP TABLE dbo.Owner
-- Thêm bảng cải tạo

-- 1. NHẬP DÂY CHUYỀN (Lane)
INSERT INTO dbo.Lane (LaneCode, LaneName, IsActive)
VALUES 
    ('DC1', N'Dây chuyền 1 - Xe con & Bán tải',      1),
    ('DC2', N'Dây chuyền 2 - Xe khách & Xe buýt',    1),
    ('DC3', N'Dây chuyền 3 - Xe tải',                1),
    ('DC4', N'Dây chuyền 4 - Xe đầu kéo & Rơ moóc',  1),
    ('DC5', N'Dây chuyền 5 - Xe mô tô & 3 bánh',     1),
    ('DC6', N'Dây chuyền 6 - Xe chuyên dùng',        1);

-- 2. NHẬP CÔNG ĐOẠN (Stage)
INSERT INTO dbo.Stage (StageCode, StageName, IsActive)
VALUES 
    ('EXTERIOR',    N'Kiểm tra ngoại thất', 1),
    ('STRUCTURE',   N'Kiểm tra khung gầm', 1),
    ('BRAKE',       N'Kiểm tra hệ thống phanh', 1),
    ('STEERING',    N'Kiểm tra hệ thống lái', 1),
    ('LIGHT',       N'Kiểm tra đèn chiếu sáng', 1),
    ('EMISSION',    N'Kiểm tra khí thải', 1),
    ('NOISE',       N'Kiểm tra tiếng ồn', 1),
    ('SPEEDOMETER', N'Kiểm tra tốc độ kế', 1),
    ('GLASS',       N'Kiểm tra kính an toàn', 1),
    ('SEATBELT',    N'Kiểm tra dây đai an toàn', 1),
    ('AXLE_LOAD',   N'Kiểm tra tải trọng trục', 1);

-- 3. CẤU HÌNH DÂY CHUYỀN 1 (Xe con 10 chỗ)
INSERT INTO dbo.LaneStage (LaneId, StageId, SortOrder, IsRequired, IsActive)
SELECT 1, s.StageId,
    CASE s.StageCode
        WHEN 'EXTERIOR'    THEN 1
        WHEN 'BRAKE'       THEN 2
        WHEN 'STEERING'    THEN 3
        WHEN 'LIGHT'       THEN 4
        WHEN 'EMISSION'    THEN 5
        WHEN 'SPEEDOMETER' THEN 6
        WHEN 'SEATBELT'    THEN 7
        WHEN 'GLASS'       THEN 8
    END,
    1, 1
FROM dbo.Stage s
WHERE s.StageCode IN (
    'EXTERIOR','BRAKE','STEERING','LIGHT',
    'EMISSION','SPEEDOMETER','SEATBELT','GLASS'
);

-- 4. CẤU HÌNH DÂY CHUYỀN 2 (Xe khách 10-40 chỗ, Xe buýt)
INSERT INTO dbo.LaneStage (LaneId, StageId, SortOrder, IsRequired, IsActive)
SELECT 2, s.StageId, 
    CASE s.StageCode
        WHEN 'BRAKE' THEN 1         -- Ưu tiên phanh
        WHEN 'STRUCTURE' THEN 2     -- Khung gầm
        WHEN 'EXTERIOR' THEN 3
        WHEN 'STEERING' THEN 4
        WHEN 'LIGHT' THEN 5
        WHEN 'EMISSION' THEN 6
        WHEN 'NOISE' THEN 7
        WHEN 'SPEEDOMETER' THEN 8
        WHEN 'GLASS' THEN 9
        WHEN 'SEATBELT' THEN 10
    END,
    1, 1
FROM dbo.Stage s
WHERE s.StageCode IN ('BRAKE', 'STRUCTURE', 'EXTERIOR', 'STEERING', 'LIGHT', 
                      'EMISSION', 'NOISE', 'SPEEDOMETER', 'GLASS', 'SEATBELT');

-- 5. CẤU HÌNH DÂY CHUYỀN 3 (Xe tải)
INSERT INTO dbo.LaneStage (LaneId, StageId, SortOrder, IsRequired, IsActive)
SELECT 3, s.StageId,
    CASE s.StageCode
        WHEN 'BRAKE' THEN 1
        WHEN 'AXLE_LOAD' THEN 2     -- Cân tải trọng
        WHEN 'STRUCTURE' THEN 3
        WHEN 'EXTERIOR' THEN 4
        WHEN 'STEERING' THEN 5
        WHEN 'LIGHT' THEN 6
        WHEN 'EMISSION' THEN 7
        WHEN 'NOISE' THEN 8
        WHEN 'SPEEDOMETER' THEN 9
    END,
    1, 1
FROM dbo.Stage s
WHERE s.StageCode IN ('BRAKE', 'AXLE_LOAD', 'STRUCTURE', 'EXTERIOR', 'STEERING', 
                      'LIGHT', 'EMISSION', 'NOISE', 'SPEEDOMETER');

-- 6. CẤU HÌNH DÂY CHUYỀN 4 (Xe đầu kéo, Rơ moóc)
INSERT INTO dbo.LaneStage (LaneId, StageId, SortOrder, IsRequired, IsActive)
SELECT 4, s.StageId,
    CASE s.StageCode
        WHEN 'BRAKE' THEN 1
        WHEN 'AXLE_LOAD' THEN 2
        WHEN 'STRUCTURE' THEN 3
        WHEN 'EXTERIOR' THEN 4
        WHEN 'STEERING' THEN 5
        WHEN 'LIGHT' THEN 6
        WHEN 'EMISSION' THEN 7
        WHEN 'NOISE' THEN 8
    END,
    1, 1
FROM dbo.Stage s
WHERE s.StageCode IN ('BRAKE', 'AXLE_LOAD', 'STRUCTURE', 'EXTERIOR', 
                      'STEERING', 'LIGHT', 'EMISSION', 'NOISE');



-- 7. CẤU HÌNH DÂY CHUYỀN 5 (Xe mô tô, 3 bánh)
INSERT INTO dbo.LaneStage (LaneId, StageId, SortOrder, IsRequired, IsActive)
SELECT 5, s.StageId,
    CASE s.StageCode
        WHEN 'EXTERIOR' THEN 1
        WHEN 'BRAKE'    THEN 2
        WHEN 'LIGHT'    THEN 3
        WHEN 'EMISSION' THEN 4
    END,
    1, 1
FROM dbo.Stage s
WHERE s.StageCode IN ('EXTERIOR', 'BRAKE', 'LIGHT', 'EMISSION');

-- 8. CẤU HÌNH DÂY CHUYỀN 6 (Xe chuyên dùng)
INSERT INTO dbo.LaneStage (LaneId, StageId, SortOrder, IsRequired, IsActive)
SELECT 6, s.StageId,
    CASE s.StageCode
        WHEN 'EXTERIOR'    THEN 1
        WHEN 'STRUCTURE'   THEN 2
        WHEN 'BRAKE'       THEN 3
        WHEN 'STEERING'    THEN 4
        WHEN 'LIGHT'       THEN 5
        WHEN 'EMISSION'    THEN 6
        WHEN 'SPEEDOMETER' THEN 7
        WHEN 'SEATBELT'    THEN 8
        WHEN 'GLASS'       THEN 9
    END,
    1, 1
FROM dbo.Stage s
WHERE s.StageCode IN (
    'EXTERIOR','STRUCTURE','BRAKE','STEERING',
    'LIGHT','EMISSION','SPEEDOMETER','SEATBELT','GLASS'
);

-- 9. NHẬP CHỈ TIÊU CHO CÔNG ĐOẠN NGOẠI THẤT
DECLARE @ExteriorStageId INT = (SELECT StageId FROM Stage WHERE StageCode = 'EXTERIOR');

INSERT INTO dbo.StageItem (StageId, ItemCode, ItemName, Unit, DataType, IsRequired, SortOrder)
VALUES 
    (@ExteriorStageId, 'EXT_BODY',        N'Tình trạng thân vỏ xe',           NULL,   'TEXT',   1, 1),
    (@ExteriorStageId, 'EXT_DOOR',        N'Cửa xe và cơ cấu đóng mở',       NULL,   'TEXT',   1, 2),
    (@ExteriorStageId, 'EXT_BUMPER',      N'Cản trước/sau',                   NULL,   'TEXT',   1, 3),
    (@ExteriorStageId, 'EXT_MIRROR',      N'Gương chiếu hậu',                 N'cái', 'NUMBER', 1, 4),
    (@ExteriorStageId, 'EXT_WIPER',       N'Cần gạt nước',                    NULL,   'TEXT',   1, 5),
    (@ExteriorStageId, 'EXT_HORN',        N'Còi xe',                          N'dB',  'NUMBER', 1, 6),
    (@ExteriorStageId, 'EXT_PLATE',       N'Biển số xe',                      NULL,   'TEXT',   1, 7),
    (@ExteriorStageId, 'EXT_TIRE_FL',     N'Lốp trước trái',                  N'mm',  'NUMBER', 1, 8),
    (@ExteriorStageId, 'EXT_TIRE_FR',     N'Lốp trước phải',                  N'mm',  'NUMBER', 1, 9),
    (@ExteriorStageId, 'EXT_TIRE_RL',     N'Lốp sau trái',                    N'mm',  'NUMBER', 1, 10),
    (@ExteriorStageId, 'EXT_TIRE_RR',     N'Lốp sau phải',                    N'mm',  'NUMBER', 1, 11);

-- 10. NHẬP CHỈ TIÊU CHO CÔNG ĐOẠN KHUNG GẦM
DECLARE @StructureStageId INT = (SELECT StageId FROM Stage WHERE StageCode = 'STRUCTURE');

INSERT INTO dbo.StageItem (StageId, ItemCode, ItemName, Unit, DataType, IsRequired, SortOrder)
VALUES 
    (@StructureStageId, 'STR_CHASSIS',      N'Khung xe (chassis)',              NULL, 'TEXT', 1, 1),
    (@StructureStageId, 'STR_SUSPENSION_F', N'Hệ thống treo trước',             NULL, 'TEXT', 1, 2),
    (@StructureStageId, 'STR_SUSPENSION_R', N'Hệ thống treo sau',               NULL, 'TEXT', 1, 3),
    (@StructureStageId, 'STR_EXHAUST',      N'Hệ thống ống xả',                 NULL, 'TEXT', 1, 4),
    (@StructureStageId, 'STR_FUEL_TANK',    N'Bình nhiên liệu',                 NULL, 'TEXT', 1, 5),
    (@StructureStageId, 'STR_DRIVESHAFT',   N'Trục truyền động',                NULL, 'TEXT', 1, 6);

-- 11. NHẬP CHỈ TIÊU CHO CÔNG ĐOẠN PHANH
DECLARE @BrakeStageId INT = (SELECT StageId FROM Stage WHERE StageCode = 'BRAKE');

INSERT INTO dbo.StageItem (StageId, ItemCode, ItemName, Unit, DataType, IsRequired, SortOrder)
VALUES 
    (@BrakeStageId, 'BRK_FORCE_FL',    N'Lực phanh bánh trước trái',       N'N',   'NUMBER', 1, 1),
    (@BrakeStageId, 'BRK_FORCE_FR',    N'Lực phanh bánh trước phải',       N'N',   'NUMBER', 1, 2),
    (@BrakeStageId, 'BRK_FORCE_RL',    N'Lực phanh bánh sau trái',         N'N',   'NUMBER', 1, 3),
    (@BrakeStageId, 'BRK_FORCE_RR',    N'Lực phanh bánh sau phải',         N'N',   'NUMBER', 1, 4),
    (@BrakeStageId, 'BRK_BALANCE_F',   N'Độ đồng đều lực phanh trục trước', N'%',  'NUMBER', 1, 5),
    (@BrakeStageId, 'BRK_BALANCE_R',   N'Độ đồng đều lực phanh trục sau',  N'%',  'NUMBER', 1, 6),
    (@BrakeStageId, 'BRK_PARKING',     N'Hiệu quả phanh đỗ',               N'%',   'NUMBER', 1, 7),
    (@BrakeStageId, 'BRK_FLUID',       N'Dầu phanh',                       NULL,   'TEXT',   1, 8),
    (@BrakeStageId, 'BRK_PEDAL',       N'Bàn đạp phanh',                   NULL,   'TEXT',   1, 9);


-- 12. NHẬP CHỈ TIÊU CHO CÔNG ĐOẠN HỆ THỐNG LÁI
DECLARE @SteeringStageId INT = (SELECT StageId FROM Stage WHERE StageCode = 'STEERING');

INSERT INTO dbo.StageItem (StageId, ItemCode, ItemName, Unit, DataType, IsRequired, SortOrder)
VALUES 
    (@SteeringStageId, 'STR_FREE_PLAY',  N'Độ rơ vô lăng',                N'độ',  'NUMBER', 1, 1),
    (@SteeringStageId, 'STR_ALIGNMENT',  N'Độ chụm bánh xe',              N'mm',  'NUMBER', 1, 2),
    (@SteeringStageId, 'STR_STABILITY',  N'Ổn định hướng',                NULL,   'TEXT',   1, 3),
    (@SteeringStageId, 'STR_MECHANISM',  N'Cơ cấu lái',                   NULL,   'TEXT',   1, 4),
    (@SteeringStageId, 'STR_POWER',      N'Trợ lực lái',                  NULL,   'TEXT',   0, 5);

-- 13. NHẬP CHỈ TIÊU CHO CÔNG ĐOẠN ĐÈN
DECLARE @LightStageId INT = (SELECT StageId FROM Stage WHERE StageCode = 'LIGHT');

INSERT INTO dbo.StageItem (StageId, ItemCode, ItemName, Unit, DataType, IsRequired, SortOrder)
VALUES 
    (@LightStageId, 'LGT_HEADLIGHT_L', N'Đèn pha trái',              N'lux', 'NUMBER', 1, 1),
    (@LightStageId, 'LGT_HEADLIGHT_R', N'Đèn pha phải',              N'lux', 'NUMBER', 1, 2),
    (@LightStageId, 'LGT_LOWBEAM_L',   N'Đèn cốt trái',              N'lux', 'NUMBER', 1, 3),
    (@LightStageId, 'LGT_LOWBEAM_R',   N'Đèn cốt phải',              N'lux', 'NUMBER', 1, 4),
    (@LightStageId, 'LGT_TURN_FL',     N'Đèn xi nhan trước trái',    NULL,   'BOOL',   1, 5),
    (@LightStageId, 'LGT_TURN_FR',     N'Đèn xi nhan trước phải',    NULL,   'BOOL',   1, 6),
    (@LightStageId, 'LGT_TURN_RL',     N'Đèn xi nhan sau trái',      NULL,   'BOOL',   1, 7),
    (@LightStageId, 'LGT_TURN_RR',     N'Đèn xi nhan sau phải',      NULL,   'BOOL',   1, 8),
    (@LightStageId, 'LGT_BRAKE',       N'Đèn phanh',                 NULL,   'BOOL',   1, 9),
    (@LightStageId, 'LGT_REVERSE',     N'Đèn lùi',                   NULL,   'BOOL',   1, 10),
    (@LightStageId, 'LGT_PLATE',       N'Đèn biển số',               NULL,   'BOOL',   1, 11);


-- 14. NHẬP CHỈ TIÊU CHO CÔNG ĐOẠN KHÍ THẢI
DECLARE @EmissionStageId INT = (SELECT StageId FROM Stage WHERE StageCode = 'EMISSION');

INSERT INTO dbo.StageItem (StageId, ItemCode, ItemName, Unit, DataType, IsRequired, SortOrder)
VALUES 
    (@EmissionStageId, 'EMI_CO',     N'Khí CO',                    N'%',   'NUMBER', 1, 1),
    (@EmissionStageId, 'EMI_HC',     N'Khí HC (Hydrocacbon)',      N'ppm', 'NUMBER', 1, 2),
    (@EmissionStageId, 'EMI_SMOKE',  N'Độ khói (diesel)',          N'%',   'NUMBER', 0, 3),
    (@EmissionStageId, 'EMI_LAMBDA', N'Hệ số Lambda',              NULL,   'NUMBER', 0, 4),
    (@EmissionStageId, 'EMI_RPM',    N'Số vòng quay động cơ',      N'rpm', 'NUMBER', 1, 5);


-- 15. NHẬP CHỈ TIÊU CHO CÁC CÔNG ĐOẠN KHÁC
-- TIẾNG ỒN
DECLARE @NoiseStageId INT = (SELECT StageId FROM Stage WHERE StageCode = 'NOISE');
INSERT INTO dbo.StageItem (StageId, ItemCode, ItemName, Unit, DataType, IsRequired, SortOrder)
VALUES 
    (@NoiseStageId, 'NOI_STATIC',  N'Tiếng ồn tĩnh',        N'dB(A)', 'NUMBER', 1, 1),
    (@NoiseStageId, 'NOI_MOVING',  N'Tiếng ồn động',        N'dB(A)', 'NUMBER', 1, 2);

-- TỐC ĐỘ KẾ
DECLARE @SpeedStageId INT = (SELECT StageId FROM Stage WHERE StageCode = 'SPEEDOMETER');
INSERT INTO dbo.StageItem (StageId, ItemCode, ItemName, Unit, DataType, IsRequired, SortOrder)
VALUES 
    (@SpeedStageId, 'SPD_ACCURACY', N'Độ chính xác tốc độ kế', N'%',  'NUMBER', 1, 1),
    (@SpeedStageId, 'SPD_ODO',      N'Số km đã đi',            N'km', 'NUMBER', 1, 2);

-- KÍNH AN TOÀN
DECLARE @GlassStageId INT = (SELECT StageId FROM Stage WHERE StageCode = 'GLASS');
INSERT INTO dbo.StageItem (StageId, ItemCode, ItemName, Unit, DataType, IsRequired, SortOrder)
VALUES 
    (@GlassStageId, 'GLS_WINDSHIELD', N'Kính chắn gió trước',  NULL, 'TEXT',   1, 1),
    (@GlassStageId, 'GLS_REAR',       N'Kính sau',             NULL, 'TEXT',   1, 2),
    (@GlassStageId, 'GLS_SIDE',       N'Kính cửa bên',         NULL, 'TEXT',   1, 3),
    (@GlassStageId, 'GLS_TINT',       N'Độ tối kính',          N'%', 'NUMBER', 1, 4);

-- DÂY ĐAI AN TOÀN
DECLARE @SeatbeltStageId INT = (SELECT StageId FROM Stage WHERE StageCode = 'SEATBELT');
INSERT INTO dbo.StageItem (StageId, ItemCode, ItemName, Unit, DataType, IsRequired, SortOrder)
VALUES 
    (@SeatbeltStageId, 'SB_DRIVER',     N'Dây đai người lái',         NULL, 'TEXT', 1, 1),
    (@SeatbeltStageId, 'SB_FRONT_PASS', N'Dây đai hành khách trước',  NULL, 'TEXT', 1, 2),
    (@SeatbeltStageId, 'SB_REAR',       N'Dây đai hàng ghế sau',      NULL, 'TEXT', 0, 3);

-- TẢI TRỌNG TRỤC
DECLARE @AxleLoadStageId INT = (SELECT StageId FROM Stage WHERE StageCode = 'AXLE_LOAD');
INSERT INTO dbo.StageItem (StageId, ItemCode, ItemName, Unit, DataType, IsRequired, SortOrder)
VALUES 
    (@AxleLoadStageId, 'AXL_FRONT', N'Tải trọng trục trước',  N'kg', 'NUMBER', 1, 1),
    (@AxleLoadStageId, 'AXL_REAR',  N'Tải trọng trục sau',    N'kg', 'NUMBER', 1, 2),
    (@AxleLoadStageId, 'AXL_TOTAL', N'Tổng tải trọng',        N'kg', 'NUMBER', 1, 3);


-- 1. XE Ô TÔ CON ≤10 CHỖ (PAX_LT_10)


DECLARE @VehicleType_PAX_LT_10 INT = (SELECT VehicleTypeId FROM VehicleType WHERE TypeCode = 'PAX_LT_10');

INSERT INTO dbo.StageItemThreshold (ItemId, VehicleTypeId, MinValue, MaxValue, PassCondition, AllowedValues, IsActive)
SELECT si.ItemId, @VehicleType_PAX_LT_10, MinVal, MaxVal, Condition, Allowed, 1
FROM dbo.StageItem si
CROSS APPLY (
    SELECT * FROM (VALUES
        -- NGOẠI THẤT
        ('EXT_TIRE_FL',     1.6,    NULL,   N'>= 1.6',                  NULL),
        ('EXT_TIRE_FR',     1.6,    NULL,   N'>= 1.6',                  NULL),
        ('EXT_TIRE_RL',     1.6,    NULL,   N'>= 1.6',                  NULL),
        ('EXT_TIRE_RR',     1.6,    NULL,   N'>= 1.6',                  NULL),
        ('EXT_MIRROR',      2,      NULL,   N'>= 2',                    NULL),
        ('EXT_HORN',        90,     115,    N'BETWEEN 90 AND 115',      NULL),
        ('EXT_BODY',        NULL,   NULL,   NULL,                       N'ĐẠT;KHÔNG ĐẠT'),
        ('EXT_DOOR',        NULL,   NULL,   NULL,                       N'ĐẠT;KHÔNG ĐẠT'),
        ('EXT_BUMPER',      NULL,   NULL,   NULL,                       N'ĐẠT;KHÔNG ĐẠT'),
        ('EXT_WIPER',       NULL,   NULL,   NULL,                       N'ĐẠT;KHÔNG ĐẠT'),
        ('EXT_PLATE',       NULL,   NULL,   NULL,                       N'ĐẠT;KHÔNG ĐẠT'),
        
        -- PHANH
        ('BRK_FORCE_FL',    450,    NULL,   N'>= 450',                  NULL),
        ('BRK_FORCE_FR',    450,    NULL,   N'>= 450',                  NULL),
        ('BRK_FORCE_RL',    350,    NULL,   N'>= 350',                  NULL),
        ('BRK_FORCE_RR',    350,    NULL,   N'>= 350',                  NULL),
        ('BRK_BALANCE_F',   NULL,   15,     N'<= 15',                   NULL),
        ('BRK_BALANCE_R',   NULL,   15,     N'<= 15',                   NULL),
        ('BRK_PARKING',     16,     NULL,   N'>= 16',                   NULL),
        ('BRK_FLUID',       NULL,   NULL,   NULL,                       N'ĐẠT;KHÔNG ĐẠT'),
        ('BRK_PEDAL',       NULL,   NULL,   NULL,                       N'ĐẠT;KHÔNG ĐẠT'),
        
        -- HỆ THỐNG LÁI
        ('STR_FREE_PLAY',   NULL,   25,     N'<= 25',                   NULL),
        ('STR_ALIGNMENT',   -3,     3,      N'BETWEEN -3 AND 3',        NULL),
        ('STR_STABILITY',   NULL,   NULL,   NULL,                       N'ĐẠT;KHÔNG ĐẠT'),
        ('STR_MECHANISM',   NULL,   NULL,   NULL,                       N'ĐẠT;KHÔNG ĐẠT'),
        
        -- ĐÈN CHIẾU SÁNG
        ('LGT_HEADLIGHT_L', 10000,  NULL,   N'>= 10000',                NULL),
        ('LGT_HEADLIGHT_R', 10000,  NULL,   N'>= 10000',                NULL),
        ('LGT_LOWBEAM_L',   5000,   NULL,   N'>= 5000',                 NULL),
        ('LGT_LOWBEAM_R',   5000,   NULL,   N'>= 5000',                 NULL),
        
        -- KHÍ THẢI (Xe xăng)
        ('EMI_CO',          NULL,   0.3,    N'<= 0.3',                  NULL),
        ('EMI_HC',          NULL,   200,    N'<= 200',                  NULL),
        ('EMI_RPM',         2000,   3000,   N'BETWEEN 2000 AND 3000',   NULL),
        
        -- TIẾNG ỒN
        ('NOI_STATIC',      NULL,   90,     N'<= 90',                   NULL),
        ('NOI_MOVING',      NULL,   84,     N'<= 84',                   NULL),
        
        -- TỐC ĐỘ KẾ
        ('SPD_ACCURACY',    NULL,   10,     N'<= 10',                   NULL),
        
        -- KÍNH
        ('GLS_WINDSHIELD',  NULL,   NULL,   NULL,                       N'ĐẠT;KHÔNG ĐẠT'),
        ('GLS_TINT',        70,     NULL,   N'>= 70',                   NULL),
        
        -- DÂY ĐAI
        ('SB_DRIVER',       NULL,   NULL,   NULL,                       N'ĐẠT;KHÔNG ĐẠT'),
        ('SB_FRONT_PASS',   NULL,   NULL,   NULL,                       N'ĐẠT;KHÔNG ĐẠT')
    ) AS T(ItemCode, MinVal, MaxVal, Condition, Allowed)
) AS Thresh(ItemCode, MinVal, MaxVal, Condition, Allowed)
WHERE si.ItemCode = Thresh.ItemCode;

-- 2. XE CỨU THƯƠNG (AMBULANCE)


DECLARE @VehicleType_AMBULANCE INT = (SELECT VehicleTypeId FROM VehicleType WHERE TypeCode = 'AMBULANCE');

INSERT INTO dbo.StageItemThreshold (ItemId, VehicleTypeId, MinValue, MaxValue, PassCondition, IsActive)
SELECT si.ItemId, @VehicleType_AMBULANCE, MinVal, MaxVal, Condition, 1
FROM dbo.StageItem si
CROSS APPLY (
    SELECT * FROM (VALUES
        ('BRK_FORCE_FL',    550,    NULL,   N'>= 550'),
        ('BRK_FORCE_FR',    550,    NULL,   N'>= 550'),
        ('BRK_FORCE_RL',    450,    NULL,   N'>= 450'),
        ('BRK_FORCE_RR',    450,    NULL,   N'>= 450'),
        ('BRK_PARKING',     17,     NULL,   N'>= 17'),
        ('STR_FREE_PLAY',   NULL,   25,     N'<= 25'),
        ('EMI_CO',          NULL,   0.4,    N'<= 0.4'),
        ('EMI_HC',          NULL,   250,    N'<= 250'),
        ('NOI_STATIC',      NULL,   92,     N'<= 92'),
        ('NOI_MOVING',      NULL,   86,     N'<= 86')
    ) AS T(ItemCode, MinVal, MaxVal, Condition)
) AS Thresh(ItemCode, MinVal, MaxVal, Condition)
WHERE si.ItemCode = Thresh.ItemCode;


-- 3. XE KHÁCH 10-24 CHỖ (PAX_10_24)


DECLARE @VehicleType_PAX_10_24 INT = (SELECT VehicleTypeId FROM VehicleType WHERE TypeCode = 'PAX_10_24');

INSERT INTO dbo.StageItemThreshold (ItemId, VehicleTypeId, MinValue, MaxValue, PassCondition, IsActive)
SELECT si.ItemId, @VehicleType_PAX_10_24, MinVal, MaxVal, Condition, 1
FROM dbo.StageItem si
CROSS APPLY (
    SELECT * FROM (VALUES
        -- PHANH (Yêu cầu cao hơn xe con)
        ('BRK_FORCE_FL',    550,    NULL,   N'>= 550'),
        ('BRK_FORCE_FR',    550,    NULL,   N'>= 550'),
        ('BRK_FORCE_RL',    450,    NULL,   N'>= 450'),
        ('BRK_FORCE_RR',    450,    NULL,   N'>= 450'),
        ('BRK_BALANCE_F',   NULL,   15,     N'<= 15'),
        ('BRK_BALANCE_R',   NULL,   15,     N'<= 15'),
        ('BRK_PARKING',     17,     NULL,   N'>= 17'),
        
        -- HỆ THỐNG LÁI
        ('STR_FREE_PLAY',   NULL,   28,     N'<= 28'),
        
        -- ĐÈN
        ('LGT_HEADLIGHT_L', 12000,  NULL,   N'>= 12000'),
        ('LGT_HEADLIGHT_R', 12000,  NULL,   N'>= 12000'),
        
        -- KHÍ THẢI
        ('EMI_CO',          NULL,   0.5,    N'<= 0.5'),
        ('EMI_HC',          NULL,   300,    N'<= 300'),
        
        -- TIẾNG ỒN
        ('NOI_STATIC',      NULL,   92,     N'<= 92'),
        ('NOI_MOVING',      NULL,   86,     N'<= 86')
    ) AS T(ItemCode, MinVal, MaxVal, Condition)
) AS Thresh(ItemCode, MinVal, MaxVal, Condition)
WHERE si.ItemCode = Thresh.ItemCode;


-- 4. XE TẢI ≤2 TẤN (TRUCK_LE_2T)


DECLARE @VehicleType_TRUCK_LE_2T INT = (SELECT VehicleTypeId FROM VehicleType WHERE TypeCode = 'TRUCK_LE_2T');

INSERT INTO dbo.StageItemThreshold (ItemId, VehicleTypeId, MinValue, MaxValue, PassCondition, IsActive)
SELECT si.ItemId, @VehicleType_TRUCK_LE_2T, MinVal, MaxVal, Condition, 1
FROM dbo.StageItem si
CROSS APPLY (
    SELECT * FROM (VALUES
        -- PHANH
        ('BRK_FORCE_FL',    500,    NULL,   N'>= 500'),
        ('BRK_FORCE_FR',    500,    NULL,   N'>= 500'),
        ('BRK_FORCE_RL',    400,    NULL,   N'>= 400'),
        ('BRK_FORCE_RR',    400,    NULL,   N'>= 400'),
        ('BRK_PARKING',     17,     NULL,   N'>= 17'),
        
        -- LÁI
        ('STR_FREE_PLAY',   NULL,   28,     N'<= 28'),
        
        -- KHÍ THẢI (Diesel)
        ('EMI_SMOKE',       NULL,   50,     N'<= 50'),
        
        -- TIẾNG ỒN
        ('NOI_STATIC',      NULL,   93,     N'<= 93'),
        ('NOI_MOVING',      NULL,   87,     N'<= 87'),
        
        -- TẢI TRỌNG
        ('AXL_FRONT',       NULL,   1500,   N'<= 1500'),
        ('AXL_REAR',        NULL,   2000,   N'<= 2000'),
        ('AXL_TOTAL',       NULL,   2000,   N'<= 2000')
    ) AS T(ItemCode, MinVal, MaxVal, Condition)
) AS Thresh(ItemCode, MinVal, MaxVal, Condition)
WHERE si.ItemCode = Thresh.ItemCode;


-- 5. XE TẢI 2-7 TẤN (TRUCK_2_7T)


DECLARE @VehicleType_TRUCK_2_7T INT = (SELECT VehicleTypeId FROM VehicleType WHERE TypeCode = 'TRUCK_2_7T');

INSERT INTO dbo.StageItemThreshold (ItemId, VehicleTypeId, MinValue, MaxValue, PassCondition, IsActive)
SELECT si.ItemId, @VehicleType_TRUCK_2_7T, MinVal, MaxVal, Condition, 1
FROM dbo.StageItem si
CROSS APPLY (
    SELECT * FROM (VALUES
        -- PHANH
        ('BRK_FORCE_FL',    600,    NULL,   N'>= 600'),
        ('BRK_FORCE_FR',    600,    NULL,   N'>= 600'),
        ('BRK_FORCE_RL',    500,    NULL,   N'>= 500'),
        ('BRK_FORCE_RR',    500,    NULL,   N'>= 500'),
        ('BRK_BALANCE_F',   NULL,   15,     N'<= 15'),
        ('BRK_BALANCE_R',   NULL,   15,     N'<= 15'),
        ('BRK_PARKING',     18,     NULL,   N'>= 18'),
        
        -- LÁI
        ('STR_FREE_PLAY',   NULL,   30,     N'<= 30'),
        
        -- ĐÈN
        ('LGT_HEADLIGHT_L', 12000,  NULL,   N'>= 12000'),
        ('LGT_HEADLIGHT_R', 12000,  NULL,   N'>= 12000'),
        
        -- KHÍ THẢI (Diesel)
        ('EMI_SMOKE',       NULL,   55,     N'<= 55'),
        
        -- TIẾNG ỒN
        ('NOI_STATIC',      NULL,   94,     N'<= 94'),
        ('NOI_MOVING',      NULL,   88,     N'<= 88'),
        
        -- TẢI TRỌNG
        ('AXL_FRONT',       NULL,   3000,   N'<= 3000'),
        ('AXL_REAR',        NULL,   5000,   N'<= 5000'),
        ('AXL_TOTAL',       NULL,   7000,   N'<= 7000')
    ) AS T(ItemCode, MinVal, MaxVal, Condition)
) AS Thresh(ItemCode, MinVal, MaxVal, Condition)
WHERE si.ItemCode = Thresh.ItemCode;


-- 6. XE KHÁCH 25-40 CHỖ (PAX_25_40)


DECLARE @VehicleType_PAX_25_40 INT = (SELECT VehicleTypeId FROM VehicleType WHERE TypeCode = 'PAX_25_40');

INSERT INTO dbo.StageItemThreshold (ItemId, VehicleTypeId, MinValue, MaxValue, PassCondition, IsActive)
SELECT si.ItemId, @VehicleType_PAX_25_40, MinVal, MaxVal, Condition, 1
FROM dbo.StageItem si
CROSS APPLY (
    SELECT * FROM (VALUES
        ('BRK_FORCE_FL',    650,    NULL,   N'>= 650'),
        ('BRK_FORCE_FR',    650,    NULL,   N'>= 650'),
        ('BRK_FORCE_RL',    550,    NULL,   N'>= 550'),
        ('BRK_FORCE_RR',    550,    NULL,   N'>= 550'),
        ('BRK_PARKING',     18,     NULL,   N'>= 18'),
        ('STR_FREE_PLAY',   NULL,   30,     N'<= 30'),
        ('EMI_SMOKE',       NULL,   55,     N'<= 55'),
        ('NOI_STATIC',      NULL,   95,     N'<= 95'),
        ('NOI_MOVING',      NULL,   88,     N'<= 88')
    ) AS T(ItemCode, MinVal, MaxVal, Condition)
) AS Thresh(ItemCode, MinVal, MaxVal, Condition)
WHERE si.ItemCode = Thresh.ItemCode;

-- 7. XE KHÁCH >40 CHỖ (PAX_GT_40)


DECLARE @VehicleType_PAX_GT_40 INT = (SELECT VehicleTypeId FROM VehicleType WHERE TypeCode = 'PAX_GT_40');

INSERT INTO dbo.StageItemThreshold (ItemId, VehicleTypeId, MinValue, MaxValue, PassCondition, IsActive)
SELECT si.ItemId, @VehicleType_PAX_GT_40, MinVal, MaxVal, Condition, 1
FROM dbo.StageItem si
CROSS APPLY (
    SELECT * FROM (VALUES
        ('BRK_FORCE_FL',    700,    NULL,   N'>= 700'),
        ('BRK_FORCE_FR',    700,    NULL,   N'>= 700'),
        ('BRK_FORCE_RL',    600,    NULL,   N'>= 600'),
        ('BRK_FORCE_RR',    600,    NULL,   N'>= 600'),
        ('BRK_PARKING',     18,     NULL,   N'>= 18'),
        ('STR_FREE_PLAY',   NULL,   30,     N'<= 30'),
        ('EMI_SMOKE',       NULL,   60,     N'<= 60'),
        ('NOI_STATIC',      NULL,   95,     N'<= 95'),
        ('NOI_MOVING',      NULL,   89,     N'<= 89')
    ) AS T(ItemCode, MinVal, MaxVal, Condition)
) AS Thresh(ItemCode, MinVal, MaxVal, Condition)
WHERE si.ItemCode = Thresh.ItemCode;

-- 8. XE BUÝT (BUS)


DECLARE @VehicleType_BUS INT = (SELECT VehicleTypeId FROM VehicleType WHERE TypeCode = 'BUS');

INSERT INTO dbo.StageItemThreshold (ItemId, VehicleTypeId, MinValue, MaxValue, PassCondition, IsActive)
SELECT si.ItemId, @VehicleType_BUS, MinVal, MaxVal, Condition, 1
FROM dbo.StageItem si
CROSS APPLY (
    SELECT * FROM (VALUES
        ('BRK_FORCE_FL',    700,    NULL,   N'>= 700'),
        ('BRK_FORCE_FR',    700,    NULL,   N'>= 700'),
        ('BRK_FORCE_RL',    600,    NULL,   N'>= 600'),
        ('BRK_FORCE_RR',    600,    NULL,   N'>= 600'),
        ('BRK_PARKING',     18,     NULL,   N'>= 18'),
        ('STR_FREE_PLAY',   NULL,   30,     N'<= 30'),
        ('EMI_SMOKE',       NULL,   60,     N'<= 60'),
        ('NOI_STATIC',      NULL,   95,     N'<= 95'),
        ('NOI_MOVING',      NULL,   89,     N'<= 89')
    ) AS T(ItemCode, MinVal, MaxVal, Condition)
) AS Thresh(ItemCode, MinVal, MaxVal, Condition)
WHERE si.ItemCode = Thresh.ItemCode;

-- 9. XE TẢI 7-20 TẤN (TRUCK_7_20T)


DECLARE @VehicleType_TRUCK_7_20T INT = (SELECT VehicleTypeId FROM VehicleType WHERE TypeCode = 'TRUCK_7_20T');

INSERT INTO dbo.StageItemThreshold (ItemId, VehicleTypeId, MinValue, MaxValue, PassCondition, IsActive)
SELECT si.ItemId, @VehicleType_TRUCK_7_20T, MinVal, MaxVal, Condition, 1
FROM dbo.StageItem si
CROSS APPLY (
    SELECT * FROM (VALUES
        ('BRK_FORCE_FL',    700,    NULL,   N'>= 700'),
        ('BRK_FORCE_FR',    700,    NULL,   N'>= 700'),
        ('BRK_FORCE_RL',    600,    NULL,   N'>= 600'),
        ('BRK_FORCE_RR',    600,    NULL,   N'>= 600'),
        ('BRK_PARKING',     18,     NULL,   N'>= 18'),
        ('STR_FREE_PLAY',   NULL,   30,     N'<= 30'),
        ('EMI_SMOKE',       NULL,   60,     N'<= 60'),
        ('NOI_STATIC',      NULL,   95,     N'<= 95'),
        ('NOI_MOVING',      NULL,   89,     N'<= 89'),
        ('AXL_FRONT',       NULL,   7000,   N'<= 7000'),
        ('AXL_REAR',        NULL,   15000,  N'<= 15000'),
        ('AXL_TOTAL',       NULL,   20000,  N'<= 20000')
    ) AS T(ItemCode, MinVal, MaxVal, Condition)
) AS Thresh(ItemCode, MinVal, MaxVal, Condition)
WHERE si.ItemCode = Thresh.ItemCode;


-- 10. XE ĐẦU KÉO ≤20 TẤN (TRACTOR_LE_20T)


DECLARE @VehicleType_TRACTOR_LE_20T INT = (SELECT VehicleTypeId FROM VehicleType WHERE TypeCode = 'TRACTOR_LE_20T');

INSERT INTO dbo.StageItemThreshold (ItemId, VehicleTypeId, MinValue, MaxValue, PassCondition, IsActive)
SELECT si.ItemId, @VehicleType_TRACTOR_LE_20T, MinVal, MaxVal, Condition, 1
FROM dbo.StageItem si
CROSS APPLY (
    SELECT * FROM (VALUES
        ('BRK_FORCE_FL',    700,    NULL,   N'>= 700'),
        ('BRK_FORCE_FR',    700,    NULL,   N'>= 700'),
        ('BRK_FORCE_RL',    600,    NULL,   N'>= 600'),
        ('BRK_FORCE_RR',    600,    NULL,   N'>= 600'),
        ('BRK_PARKING',     18,     NULL,   N'>= 18'),
        ('STR_FREE_PLAY',   NULL,   30,     N'<= 30'),
        ('EMI_SMOKE',       NULL,   60,     N'<= 60'),
        ('NOI_STATIC',      NULL,   95,     N'<= 95')
    ) AS T(ItemCode, MinVal, MaxVal, Condition)
) AS Thresh(ItemCode, MinVal, MaxVal, Condition)
WHERE si.ItemCode = Thresh.ItemCode;


-- 11. XE TẢI >20 TẤN (TRUCK_GT_20T)


DECLARE @VehicleType_TRUCK_GT_20T INT = (SELECT VehicleTypeId FROM VehicleType WHERE TypeCode = 'TRUCK_GT_20T');

INSERT INTO dbo.StageItemThreshold (ItemId, VehicleTypeId, MinValue, MaxValue, PassCondition, IsActive)
SELECT si.ItemId, @VehicleType_TRUCK_GT_20T, MinVal, MaxVal, Condition, 1
FROM dbo.StageItem si
CROSS APPLY (
    SELECT * FROM (VALUES
        ('BRK_FORCE_FL',    750,    NULL,   N'>= 750'),
        ('BRK_FORCE_FR',    750,    NULL,   N'>= 750'),
        ('BRK_FORCE_RL',    650,    NULL,   N'>= 650'),
        ('BRK_FORCE_RR',    650,    NULL,   N'>= 650'),
        ('BRK_PARKING',     18,     NULL,   N'>= 18'),
        ('STR_FREE_PLAY',   NULL,   30,     N'<= 30'),
        ('EMI_SMOKE',       NULL,   65,     N'<= 65'),
        ('NOI_STATIC',      NULL,   96,     N'<= 96'),
        ('NOI_MOVING',      NULL,   90,     N'<= 90'),
        ('AXL_FRONT',       NULL,   7500,   N'<= 7500'),
        ('AXL_REAR',        NULL,   18000,  N'<= 18000'),
        ('AXL_TOTAL',       NULL,   25000,  N'<= 25000')
    ) AS T(ItemCode, MinVal, MaxVal, Condition)
) AS Thresh(ItemCode, MinVal, MaxVal, Condition)
WHERE si.ItemCode = Thresh.ItemCode;

-- 12. XE ĐẦU KÉO >20 TẤN (TRACTOR_GT_20T)


DECLARE @VehicleType_TRACTOR_GT_20T INT = (SELECT VehicleTypeId FROM VehicleType WHERE TypeCode = 'TRACTOR_GT_20T');

INSERT INTO dbo.StageItemThreshold (ItemId, VehicleTypeId, MinValue, MaxValue, PassCondition, IsActive)
SELECT si.ItemId, @VehicleType_TRACTOR_GT_20T, MinVal, MaxVal, Condition, 1
FROM dbo.StageItem si
CROSS APPLY (
    SELECT * FROM (VALUES
        ('BRK_FORCE_FL',    750,    NULL,   N'>= 750'),
        ('BRK_FORCE_FR',    750,    NULL,   N'>= 750'),
        ('BRK_FORCE_RL',    650,    NULL,   N'>= 650'),
('BRK_FORCE_RR',    650,    NULL,   N'>= 650'),
('BRK_PARKING',     18,     NULL,   N'>= 18'),
('STR_FREE_PLAY',   NULL,   30,     N'<= 30'),
('EMI_SMOKE',       NULL,   65,     N'<= 65'),
('NOI_STATIC',      NULL,   96,     N'<= 96')
) AS T(ItemCode, MinVal, MaxVal, Condition)
) AS Thresh(ItemCode, MinVal, MaxVal, Condition)
WHERE si.ItemCode = Thresh.ItemCode;

-- 13. MÁY KÉO (TRACTOR)

DECLARE @VehicleType_TRACTOR INT = (SELECT VehicleTypeId FROM VehicleType WHERE TypeCode = 'TRACTOR');
INSERT INTO dbo.StageItemThreshold (ItemId, VehicleTypeId, MinValue, MaxValue, PassCondition, IsActive)
SELECT si.ItemId, @VehicleType_TRACTOR, MinVal, MaxVal, Condition, 1
FROM dbo.StageItem si
CROSS APPLY (
SELECT * FROM (VALUES
('BRK_FORCE_FL',    400,    NULL,   N'>= 400'),
('BRK_FORCE_FR',    400,    NULL,   N'>= 400'),
('BRK_PARKING',     16,     NULL,   N'>= 16'),
('STR_FREE_PLAY',   NULL,   35,     N'<= 35'),
('EMI_SMOKE',       NULL,   70,     N'<= 70'),
('NOI_STATIC',      NULL,   98,     N'<= 98')
) AS T(ItemCode, MinVal, MaxVal, Condition)
) AS Thresh(ItemCode, MinVal, MaxVal, Condition)
WHERE si.ItemCode = Thresh.ItemCode;

-- 14. XE CHỞ HÀNG 4 BÁNH GẮN ĐỘNG CƠ (MOTOR_4W_CARGO)

DECLARE @VehicleType_MOTOR_4W_CARGO INT = (SELECT VehicleTypeId FROM VehicleType WHERE TypeCode = 'MOTOR_4W_CARGO');
INSERT INTO dbo.StageItemThreshold (ItemId, VehicleTypeId, MinValue, MaxValue, PassCondition, IsActive)
SELECT si.ItemId, @VehicleType_MOTOR_4W_CARGO, MinVal, MaxVal, Condition, 1
FROM dbo.StageItem si
CROSS APPLY (
SELECT * FROM (VALUES
('EXT_TIRE_FL',     0.8,    NULL,   N'>= 0.8'),
('EXT_TIRE_FR',     0.8,    NULL,   N'>= 0.8'),
('BRK_FORCE_FL',    150,    NULL,   N'>= 150'),
('BRK_FORCE_FR',    150,    NULL,   N'>= 150'),
('EMI_CO',          NULL,   4.5,    N'<= 4.5'),
('EMI_HC',          NULL,   2000,   N'<= 2000'),
('NOI_STATIC',      NULL,   85,     N'<= 85')
) AS T(ItemCode, MinVal, MaxVal, Condition)
) AS Thresh(ItemCode, MinVal, MaxVal, Condition)
WHERE si.ItemCode = Thresh.ItemCode;

-- 15. XE CHỞ NGƯỜI 4 BÁNH GẮN ĐỘNG CƠ (MOTOR_4W_PAX)

DECLARE @VehicleType_MOTOR_4W_PAX INT = (SELECT VehicleTypeId FROM VehicleType WHERE TypeCode = 'MOTOR_4W_PAX');
INSERT INTO dbo.StageItemThreshold (ItemId, VehicleTypeId, MinValue, MaxValue, PassCondition, IsActive)
SELECT si.ItemId, @VehicleType_MOTOR_4W_PAX, MinVal, MaxVal, Condition, 1
FROM dbo.StageItem si
CROSS APPLY (
SELECT * FROM (VALUES
('EXT_TIRE_FL',     0.8,    NULL,   N'>= 0.8'),
('EXT_TIRE_FR',     0.8,    NULL,   N'>= 0.8'),
('BRK_FORCE_FL',    150,    NULL,   N'>= 150'),
('BRK_FORCE_FR',    150,    NULL,   N'>= 150'),
('EMI_CO',          NULL,   4.5,    N'<= 4.5'),
('EMI_HC',          NULL,   2000,   N'<= 2000'),
('NOI_STATIC',      NULL,   85,     N'<= 85')
) AS T(ItemCode, MinVal, MaxVal, Condition)
) AS Thresh(ItemCode, MinVal, MaxVal, Condition)
WHERE si.ItemCode = Thresh.ItemCode;

-- 16. RƠ MOÓC (TRAILER)

DECLARE @VehicleType_TRAILER INT = (SELECT VehicleTypeId FROM VehicleType WHERE TypeCode = 'TRAILER');
INSERT INTO dbo.StageItemThreshold (ItemId, VehicleTypeId, MinValue, MaxValue, PassCondition, IsActive)
SELECT si.ItemId, @VehicleType_TRAILER, MinVal, MaxVal, Condition, 1
FROM dbo.StageItem si
CROSS APPLY (
SELECT * FROM (VALUES
('BRK_FORCE_RL',    500,    NULL,   N'>= 500'),
('BRK_FORCE_RR',    500,    NULL,   N'>= 500'),
('BRK_PARKING',     16,     NULL,   N'>= 16'),
('AXL_REAR',        NULL,   18000,  N'<= 18000'),
('AXL_TOTAL',       NULL,   24000,  N'<= 24000')
) AS T(ItemCode, MinVal, MaxVal, Condition)
) AS Thresh(ItemCode, MinVal, MaxVal, Condition)
WHERE si.ItemCode = Thresh.ItemCode;

-- 17. SƠ MI RƠ MOÓC (SEMI_TRAILER)

DECLARE @VehicleType_SEMI_TRAILER INT = (SELECT VehicleTypeId FROM VehicleType WHERE TypeCode = 'SEMI_TRAILER');
INSERT INTO dbo.StageItemThreshold (ItemId, VehicleTypeId, MinValue, MaxValue, PassCondition, IsActive)
SELECT si.ItemId, @VehicleType_SEMI_TRAILER, MinVal, MaxVal, Condition, 1
FROM dbo.StageItem si
CROSS APPLY (
SELECT * FROM (VALUES
('BRK_FORCE_RL',    500,    NULL,   N'>= 500'),
('BRK_FORCE_RR',    500,    NULL,   N'>= 500'),
('BRK_PARKING',     16,     NULL,   N'>= 16'),
('AXL_REAR',        NULL,   20000,  N'<= 20000'),
('AXL_TOTAL',       NULL,   28000,  N'<= 28000')
) AS T(ItemCode, MinVal, MaxVal, Condition)
) AS Thresh(ItemCode, MinVal, MaxVal, Condition)
WHERE si.ItemCode = Thresh.ItemCode;

-- 18. XE BA BÁNH (THREE_WHEEL)

DECLARE @VehicleType_THREE_WHEEL INT = (SELECT VehicleTypeId FROM VehicleType WHERE TypeCode = 'THREE_WHEEL');
INSERT INTO dbo.StageItemThreshold (ItemId, VehicleTypeId, MinValue, MaxValue, PassCondition, IsActive)
SELECT si.ItemId, @VehicleType_THREE_WHEEL, MinVal, MaxVal, Condition, 1
FROM dbo.StageItem si
CROSS APPLY (
SELECT * FROM (VALUES
('EXT_TIRE_FL',     0.8,    NULL,   N'>= 0.8'),
('EXT_TIRE_FR',     0.8,    NULL,   N'>= 0.8'),
('BRK_FORCE_FL',    150,    NULL,   N'>= 150'),
('BRK_FORCE_FR',    150,    NULL,   N'>= 150'),
('EMI_CO',          NULL,   4.5,    N'<= 4.5'),
('EMI_HC',          NULL,   2000,   N'<= 2000'),
('NOI_STATIC',      NULL,   85,     N'<= 85')
) AS T(ItemCode, MinVal, MaxVal, Condition)
) AS Thresh(ItemCode, MinVal, MaxVal, Condition)
WHERE si.ItemCode = Thresh.ItemCode;

SELECT *
FROM FeeSchedule F
JOIN VehicleType T ON T.VehicleTypeId = F.VehicleTypeId

INSERT INTO dbo.VehicleType(TypeCode, TypeName, Description, IsActive)
VALUES
-- 250k
('PAX_LT_10',   N'Ô tô chở người dưới 10 chỗ',      N'Theo biểu phí kiểm định', 1),
('AMBULANCE',   N'Xe cứu thương',                   N'Theo biểu phí kiểm định', 1),

-- 290k
('PAX_10_24',   N'Ô tô chở người 10 đến 24 ghế',    N'Kể cả taxi', 1),
('TRUCK_LE_2T', N'Ô tô tải đến 2 tấn',              N'KL hàng chuyên chở cho phép tham gia GT đến 2 tấn', 1),

-- 330k
('PAX_25_40',   N'Ô tô chở người 25 đến 40 ghế',    N'Kể cả taxi', 1),
('TRUCK_2_7T',  N'Ô tô tải trên 2 đến 7 tấn',       N'KL hàng chuyên chở cho phép tham gia GT trên 2 đến 7 tấn', 1),

-- 360k
('PAX_GT_40',     N'Ô tô chở người trên 40 ghế',    N'Kể cả taxi', 1),
('BUS',           N'Xe buýt',                        N'Theo biểu phí kiểm định', 1),
('TRUCK_7_20T',   N'Ô tô tải trên 7 đến 20 tấn',     N'Theo biểu phí kiểm định', 1),
('TRACTOR_LE_20T',N'Ô tô đầu kéo kéo theo đến 20 tấn',N'Khối lượng kéo theo cho phép tham gia GT đến 20 tấn', 1),

-- 570k
('TRUCK_GT_20T',   N'Ô tô tải trên 20 tấn',          N'Theo biểu phí kiểm định', 1),
('TRACTOR_GT_20T', N'Ô tô đầu kéo kéo theo trên 20 tấn', N'Khối lượng kéo theo cho phép tham gia GT trên 20 tấn', 1),

-- 190k (bảng dưới)
('TRACTOR',      N'Máy kéo',                         N'Theo biểu phí kiểm định', 1),
('MOTOR_4W_CARGO',N'Xe chở hàng 4 bánh gắn động cơ', N'Theo biểu phí kiểm định', 1),
('MOTOR_4W_PAX',  N'Xe chở người 4 bánh gắn động cơ',N'Theo biểu phí kiểm định', 1),
('TRAILER',       N'Rơ-moóc',                        N'Theo biểu phí kiểm định', 1),
('SEMI_TRAILER',  N'Sơ mi rơ-moóc',                  N'Theo biểu phí kiểm định', 1),

-- 110k
('THREE_WHEEL',   N'Xe ba bánh',                     N'Theo biểu phí kiểm định', 1);

--------------
DECLARE @From DATE = '2022-10-08'; -- bạn có thể đổi
DECLARE @CreatedBy UNIQUEIDENTIFIER = NULL;

-- helper: lấy id theo TypeCode
DECLARE @Id TABLE (TypeCode NVARCHAR(20), VehicleTypeId INT);
INSERT INTO @Id(TypeCode, VehicleTypeId)
SELECT TypeCode, VehicleTypeId FROM dbo.VehicleType
WHERE TypeCode IN (
 'PAX_LT_10','AMBULANCE',
 'PAX_10_24','TRUCK_LE_2T',
 'PAX_25_40','TRUCK_2_7T',
 'PAX_GT_40','BUS','TRUCK_7_20T','TRACTOR_LE_20T',
 'TRUCK_GT_20T','TRACTOR_GT_20T',
 'TRACTOR','MOTOR_4W_CARGO','MOTOR_4W_PAX','TRAILER','SEMI_TRAILER',
 'THREE_WHEEL'
);

-- Insert phí theo nhóm tiền trong ảnh
INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'PERIODIC', VehicleTypeId, 250000, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('PAX_LT_10','AMBULANCE');

INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'PERIODIC', VehicleTypeId, 290000, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('PAX_10_24','TRUCK_LE_2T');

INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'PERIODIC', VehicleTypeId, 330000, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('PAX_25_40','TRUCK_2_7T');

INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'PERIODIC', VehicleTypeId, 360000, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('PAX_GT_40','BUS','TRUCK_7_20T','TRACTOR_LE_20T');

INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'PERIODIC', VehicleTypeId, 570000, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('TRUCK_GT_20T','TRACTOR_GT_20T');

INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'PERIODIC', VehicleTypeId, 190000, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('TRACTOR','MOTOR_4W_CARGO','MOTOR_4W_PAX','TRAILER','SEMI_TRAILER');

INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'PERIODIC', VehicleTypeId, 110000, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('THREE_WHEEL');

--------------
DECLARE @From DATE = '2022-10-08'; -- bạn có thể đổi
DECLARE @CreatedBy UNIQUEIDENTIFIER = NULL;

-- helper: lấy id theo TypeCode
DECLARE @Id TABLE (TypeCode NVARCHAR(20), VehicleTypeId INT);
INSERT INTO @Id(TypeCode, VehicleTypeId)
SELECT TypeCode, VehicleTypeId FROM dbo.VehicleType
WHERE TypeCode IN (
 'PAX_LT_10','AMBULANCE',
 'PAX_10_24','TRUCK_LE_2T',
 'PAX_25_40','TRUCK_2_7T',
 'PAX_GT_40','BUS','TRUCK_7_20T','TRACTOR_LE_20T',
 'TRUCK_GT_20T','TRACTOR_GT_20T',
 'TRACTOR','MOTOR_4W_CARGO','MOTOR_4W_PAX','TRAILER','SEMI_TRAILER',
 'THREE_WHEEL'
);
-- Insert phí theo nhóm tiền trong ảnh
INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'FIRST', VehicleTypeId, 0, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('PAX_LT_10','AMBULANCE');

INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'FIRST', VehicleTypeId, 0, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('PAX_10_24','TRUCK_LE_2T');

INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'FIRST', VehicleTypeId, 0, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('PAX_25_40','TRUCK_2_7T');

INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'FIRST', VehicleTypeId, 0, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('PAX_GT_40','BUS','TRUCK_7_20T','TRACTOR_LE_20T');

INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'FIRST', VehicleTypeId, 0, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('TRUCK_GT_20T','TRACTOR_GT_20T');

INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'FIRST', VehicleTypeId, 0, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('TRACTOR','MOTOR_4W_CARGO','MOTOR_4W_PAX','TRAILER','SEMI_TRAILER');

INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'FIRST', VehicleTypeId, 0, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('THREE_WHEEL');


--------------
DECLARE @From DATE = '2022-10-08'; -- bạn có thể đổi
DECLARE @CreatedBy UNIQUEIDENTIFIER = NULL;

-- helper: lấy id theo TypeCode
DECLARE @Id TABLE (TypeCode NVARCHAR(20), VehicleTypeId INT);
INSERT INTO @Id(TypeCode, VehicleTypeId)
SELECT TypeCode, VehicleTypeId FROM dbo.VehicleType
WHERE TypeCode IN (
 'PAX_LT_10','AMBULANCE',
 'PAX_10_24','TRUCK_LE_2T',
 'PAX_25_40','TRUCK_2_7T',
 'PAX_GT_40','BUS','TRUCK_7_20T','TRACTOR_LE_20T',
 'TRUCK_GT_20T','TRACTOR_GT_20T',
 'TRACTOR','MOTOR_4W_CARGO','MOTOR_4W_PAX','TRAILER','SEMI_TRAILER',
 'THREE_WHEEL'
);
-- Insert phí theo nhóm tiền trong ảnh
INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'RE_INSPECTION', VehicleTypeId, 125000, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('PAX_LT_10','AMBULANCE');

INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'RE_INSPECTION', VehicleTypeId, 145000, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('PAX_10_24','TRUCK_LE_2T');

INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'RE_INSPECTION', VehicleTypeId, 165000, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('PAX_25_40','TRUCK_2_7T');

INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'RE_INSPECTION', VehicleTypeId, 180000, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('PAX_GT_40','BUS','TRUCK_7_20T','TRACTOR_LE_20T');

INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'RE_INSPECTION', VehicleTypeId, 285000, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('TRUCK_GT_20T','TRACTOR_GT_20T');

INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'RE_INSPECTION', VehicleTypeId, 95000, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('TRACTOR','MOTOR_4W_CARGO','MOTOR_4W_PAX','TRAILER','SEMI_TRAILER');

INSERT INTO dbo.FeeSchedule
(ServiceType, VehicleTypeId, BaseFee, CertificateFee, StickerFee, TotalFee, EffectiveFrom, EffectiveTo, IsActive, CreatedBy)
SELECT N'RE_INSPECTION', VehicleTypeId, 55000, 90000, 49680, 0, @From, NULL, 1, @CreatedBy
FROM @Id WHERE TypeCode IN ('THREE_WHEEL');


INSERT INTO LaneVehicleType (LaneId, VehicleTypeId)
VALUES
(1, 9),   -- PAX_LT_10
(1, 11),  -- PAX_10_24
(1, 13);  -- PAX_25_40
INSERT INTO LaneVehicleType (LaneId, VehicleTypeId)
VALUES
(2, 13), -- PAX_25_40
(2, 16); -- BUS
INSERT INTO LaneVehicleType (LaneId, VehicleTypeId)
VALUES
(3, 12), -- TRUCK_LE_2T
(3, 14), -- TRUCK_2_7T
(3, 17); -- TRUCK_7_20T
INSERT INTO LaneVehicleType (LaneId, VehicleTypeId)
VALUES
(4, 18), -- TRACTOR_LE_20T
(4, 19), -- TRUCK_GT_20T
(4, 24), -- TRAILER
(4, 25); -- SEMI_TRAILER
INSERT INTO LaneVehicleType (LaneId, VehicleTypeId)
VALUES
(5, 15), -- MOTOR_4W_CARGO
(5, 16), -- MOTOR_4W_PAX
(5, 26); -- THREE_WHEEL


