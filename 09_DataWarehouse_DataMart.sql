/* ============================================================================
   PROYECTO: SISTEMA DE GESTIÓN MUNICIPALIDAD DE NICOYA 2026
   (DIMENSIONES, HECHOS Y FUNCIONES ANALÍTICAS FUN-19 A FUN-22)
   ============================================================================ */

USE master;
GO

-- 1. Recreación limpia de la base de datos analítica DataMart
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'MunicipalidadNicoyaDataMart2026')
BEGIN
    ALTER DATABASE MunicipalidadNicoyaDataMart2026 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MunicipalidadNicoyaDataMart2026;
    PRINT '-> DataMart anterior eliminado.';
END
GO

CREATE DATABASE MunicipalidadNicoyaDataMart2026
ON PRIMARY
(
    NAME = 'Nicoya2026_DW_Data',
    FILENAME = 'C:\SQLData\Nicoya2026_DW_Data.mdf',
    SIZE = 128MB,
    MAXSIZE = 10GB,
    FILEGROWTH = 32MB
)
LOG ON
(
    NAME = 'Nicoya2026_DW_Log',
    FILENAME = 'C:\SQLLOG\Nicoya2026_DW_Log.ldf',
    SIZE = 64MB,
    MAXSIZE = 5GB,
    FILEGROWTH = 16MB
);
GO

USE MunicipalidadNicoyaDataMart2026;
GO

PRINT '=======================================================';
PRINT '   CREACIÓN DE TABLAS DIMENSIONALES (ESQUEMA ESTRELLA)';
PRINT '=======================================================';
GO

-- ============================================================================
-- 1. TABLAS DIMENSIONALES (DIM_*)
-- ============================================================================

-- 1.1 DIM_TIEMPO
CREATE TABLE DIM_TIEMPO
(
    id_tiempo      INT           IDENTITY(1,1) NOT NULL,
    fecha          DATE          NOT NULL,
    anio           INT           NOT NULL,
    trimestre      INT           NOT NULL,
    mes            INT           NOT NULL,
    nombre_mes     VARCHAR(20)   NOT NULL,
    dia            INT           NOT NULL,
    dia_semana     INT           NOT NULL,
    nombre_dia     VARCHAR(20)   NOT NULL,
    es_fin_semana  BIT           NOT NULL,
    CONSTRAINT PK_DIM_TIEMPO     PRIMARY KEY (id_tiempo),
    CONSTRAINT UQ_DIM_TIEMPO_fec UNIQUE (fecha)
);
GO

-- 1.2 DIM_CONTRIBUYENTE
CREATE TABLE DIM_CONTRIBUYENTE
(
    id_contribuyente_dw     INT          IDENTITY(1,1) NOT NULL,
    id_contribuyente_origen INT          NOT NULL,
    tipo_persona            VARCHAR(10)  NOT NULL,
    distrito_residencia     VARCHAR(50)  NULL,
    fecha_registro          DATE         NOT NULL,
    CONSTRAINT PK_DIM_CONTRIBUYENTE      PRIMARY KEY (id_contribuyente_dw),
    CONSTRAINT UQ_DIM_CONTRIBUYENTE_orig UNIQUE (id_contribuyente_origen)
);
GO

-- 1.3 DIM_UBICACION
CREATE TABLE DIM_UBICACION
(
    id_ubicacion_dw    INT          IDENTITY(1,1) NOT NULL,
    id_distrito_origen INT          NOT NULL,
    distrito           VARCHAR(50)  NOT NULL,
    zona_rural_urbana  VARCHAR(10)  NOT NULL,
    CONSTRAINT PK_DIM_UBICACION     PRIMARY KEY (id_ubicacion_dw),
    CONSTRAINT UQ_DIM_UBICACION_orig UNIQUE (id_distrito_origen)
);
GO

-- 1.4 DIM_TRIBUTO
CREATE TABLE DIM_TRIBUTO
(
    id_tributo_dw          INT          IDENTITY(1,1) NOT NULL,
    id_tipo_tributo_origen INT          NOT NULL,
    codigo_tributo         VARCHAR(20)  NOT NULL,
    nombre_tributo         VARCHAR(100) NOT NULL,
    categoria_tributo      VARCHAR(50)  NOT NULL,
    periodicidad           VARCHAR(20)  NOT NULL,
    CONSTRAINT PK_DIM_TRIBUTO           PRIMARY KEY (id_tributo_dw),
    CONSTRAINT UQ_DIM_TRIBUTO_orig      UNIQUE (id_tipo_tributo_origen)
);
GO

-- 1.5 DIM_TRAMITE
CREATE TABLE DIM_TRAMITE
(
    id_tramite_dw             INT          IDENTITY(1,1) NOT NULL,
    id_tipo_tramite_origen    INT          NOT NULL,
    nombre_tramite            VARCHAR(100) NOT NULL,
    departamento_responsable  VARCHAR(50)  NOT NULL,
    plazo_dias_resolucion     INT          NOT NULL,
    CONSTRAINT PK_DIM_TRAMITE              PRIMARY KEY (id_tramite_dw),
    CONSTRAINT UQ_DIM_TRAMITE_orig         UNIQUE (id_tipo_tramite_origen)
);
GO

-- 1.6 DIM_DEPARTAMENTO
CREATE TABLE DIM_DEPARTAMENTO
(
    id_departamento_dw     INT          IDENTITY(1,1) NOT NULL,
    id_departamento_origen INT          NOT NULL,
    nombre_departamento    VARCHAR(50)  NOT NULL,
    codigo_interno         INT          NOT NULL,
    CONSTRAINT PK_DIM_DEPARTAMENTO      PRIMARY KEY (id_departamento_dw),
    CONSTRAINT UQ_DIM_DEPARTAMENTO_orig UNIQUE (id_departamento_origen)
);
GO

-- ============================================================================
-- 2. TABLAS DE HECHOS (FACT_*)
-- ============================================================================

-- 2.1 FACT_RECAUDACION
CREATE TABLE FACT_RECAUDACION
(
    id_recaudacion      INT            IDENTITY(1,1) NOT NULL,
    id_tiempo           INT            NOT NULL,
    id_contribuyente_dw INT            NOT NULL,
    id_ubicacion_dw     INT            NOT NULL,
    id_tributo_dw       INT            NOT NULL,
    monto_recaudado     DECIMAL(12,2)  NOT NULL,
    monto_intereses     DECIMAL(12,2)  NOT NULL,
    monto_descuento     DECIMAL(12,2)  NOT NULL,
    CONSTRAINT PK_FACT_RECAUDACION         PRIMARY KEY (id_recaudacion),
    CONSTRAINT FK_FACT_REC_Tiempo          FOREIGN KEY (id_tiempo) REFERENCES DIM_TIEMPO(id_tiempo),
    CONSTRAINT FK_FACT_REC_Contribuyente   FOREIGN KEY (id_contribuyente_dw) REFERENCES DIM_CONTRIBUYENTE(id_contribuyente_dw),
    CONSTRAINT FK_FACT_REC_Ubicacion       FOREIGN KEY (id_ubicacion_dw) REFERENCES DIM_UBICACION(id_ubicacion_dw),
    CONSTRAINT FK_FACT_REC_Tributo         FOREIGN KEY (id_tributo_dw) REFERENCES DIM_TRIBUTO(id_tributo_dw)
);
GO

-- 2.2 FACT_MOROSIDAD
CREATE TABLE FACT_MOROSIDAD
(
    id_morosidad                    INT            IDENTITY(1,1) NOT NULL,
    id_tiempo                       INT            NOT NULL,
    id_ubicacion_dw                 INT            NOT NULL,
    id_tributo_dw                   INT            NOT NULL,
    saldo_vencido                   DECIMAL(12,2)  NOT NULL,
    cantidad_contribuyentes_morosos INT            NOT NULL,
    CONSTRAINT PK_FACT_MOROSIDAD           PRIMARY KEY (id_morosidad),
    CONSTRAINT FK_FACT_MOR_Tiempo          FOREIGN KEY (id_tiempo) REFERENCES DIM_TIEMPO(id_tiempo),
    CONSTRAINT FK_FACT_MOR_Ubicacion       FOREIGN KEY (id_ubicacion_dw) REFERENCES DIM_UBICACION(id_ubicacion_dw),
    CONSTRAINT FK_FACT_MOR_Tributo         FOREIGN KEY (id_tributo_dw) REFERENCES DIM_TRIBUTO(id_tributo_dw)
);
GO

-- 2.3 FACT_EFICIENCIA_TRAMITES
CREATE TABLE FACT_EFICIENCIA_TRAMITES
(
    id_eficiencia          INT          IDENTITY(1,1) NOT NULL,
    id_tiempo              INT          NOT NULL,
    id_tramite_dw          INT          NOT NULL,
    id_departamento_dw     INT          NOT NULL,
    dias_resolucion        INT          NOT NULL,
    estado_final           VARCHAR(20)  NOT NULL,
    cantidad_tramites      INT          NOT NULL,
    CONSTRAINT PK_FACT_EFICIENCIA          PRIMARY KEY (id_eficiencia),
    CONSTRAINT FK_FACT_EFI_Tiempo          FOREIGN KEY (id_tiempo) REFERENCES DIM_TIEMPO(id_tiempo),
    CONSTRAINT FK_FACT_EFI_Tramite         FOREIGN KEY (id_tramite_dw) REFERENCES DIM_TRAMITE(id_tramite_dw),
    CONSTRAINT FK_FACT_EFI_Departamento    FOREIGN KEY (id_departamento_dw) REFERENCES DIM_DEPARTAMENTO(id_departamento_dw)
);
GO

PRINT '-> Tablas dimensionales y de hechos creadas exitosamente.';
GO

-- ============================================================================
-- 3. FUNCIONES ANALÍTICAS DEL DATA WAREHOUSE (FUN-19 A FUN-22)
-- ============================================================================

-- FUN-19: fn_dw_total_recaudacion_periodo
CREATE OR ALTER FUNCTION dbo.fn_dw_total_recaudacion_periodo
(
    @fecha_inicio DATE,
    @fecha_fin DATE
)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @total DECIMAL(12,2) = 0;

    SELECT @total = SUM(fr.monto_recaudado + fr.monto_intereses)
    FROM dbo.FACT_RECAUDACION fr
    INNER JOIN dbo.DIM_TIEMPO dt ON fr.id_tiempo = dt.id_tiempo
    WHERE dt.fecha >= @fecha_inicio AND dt.fecha <= @fecha_fin;

    RETURN ISNULL(@total, 0);
END;
GO

-- FUN-20: fn_dw_total_recaudacion_distrito
CREATE OR ALTER FUNCTION dbo.fn_dw_total_recaudacion_distrito
(
    @distrito VARCHAR(50)
)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @total DECIMAL(12,2) = 0;

    SELECT @total = SUM(fr.monto_recaudado + fr.monto_intereses)
    FROM dbo.FACT_RECAUDACION fr
    INNER JOIN dbo.DIM_UBICACION du ON fr.id_ubicacion_dw = du.id_ubicacion_dw
    WHERE du.distrito = @distrito;

    RETURN ISNULL(@total, 0);
END;
GO

-- FUN-21: fn_dw_porcentaje_morosidad
CREATE OR ALTER FUNCTION dbo.fn_dw_porcentaje_morosidad
(
    @id_tiempo INT
)
RETURNS FLOAT
AS
BEGIN
    DECLARE @total_morosos INT = 0;
    DECLARE @total_contribuyentes INT = 0;
    DECLARE @pct FLOAT = 0;

    SELECT @total_morosos = SUM(cantidad_contribuyentes_morosos)
    FROM dbo.FACT_MOROSIDAD
    WHERE id_tiempo = @id_tiempo;

    SELECT @total_contribuyentes = COUNT(*) FROM dbo.DIM_CONTRIBUYENTE;

    IF @total_contribuyentes > 0
        SET @pct = (@total_morosos * 100.0) / @total_contribuyentes;

    RETURN @pct;
END;
GO

-- FUN-22: fn_dw_promedio_dias_resolucion
CREATE OR ALTER FUNCTION dbo.fn_dw_promedio_dias_resolucion
(
    @id_tramite_dw INT = NULL,
    @id_departamento_dw INT = NULL
)
RETURNS FLOAT
AS
BEGIN
    DECLARE @promedio FLOAT = 0;

    SELECT @promedio = AVG(CAST(dias_resolucion AS FLOAT))
    FROM dbo.FACT_EFICIENCIA_TRAMITES
    WHERE (@id_tramite_dw IS NULL OR id_tramite_dw = @id_tramite_dw)
      AND (@id_departamento_dw IS NULL OR id_departamento_dw = @id_departamento_dw);

    RETURN ISNULL(@promedio, 0);
END;
GO

PRINT '-> DataMart y Funciones Dimensionales (FUN-19 a FUN-22) compiladas exitosamente.';
GO
