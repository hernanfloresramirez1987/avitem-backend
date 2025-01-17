-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jan 16, 2025 at 02:01 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `avitem_prueba`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `descontar_inventario` (IN `p_id_producto` INT, IN `p_cantidad` INT)   BEGIN
  DECLARE v_cantidadRestante INT;
  DECLARE v_lote_id INT;
  DECLARE v_lote_cantidadDisponible INT;


  -- Inicializar la cantidad restante con la cantidad solicitada
  SET v_cantidadRestante = p_cantidad;


  -- Bucle para descontar del inventario
  WHILE v_cantidadRestante > 0 DO
      -- Seleccionar el lote más antiguo con disponibilidad
      SELECT id, (cantidadReabastecida - cantidadDespachada) AS cantidadDisponible
      INTO v_lote_id, v_lote_cantidadDisponible
      FROM lote_producto
      WHERE id_producto = p_id_producto AND (cantidadReabastecida - cantidadDespachada) > 0
      ORDER BY fechaReabastecimiento ASC
      LIMIT 1;


      -- Si no hay más lotes disponibles, finalizar con un error
      IF v_lote_id IS NULL THEN
          SIGNAL SQLSTATE '45000'
          SET MESSAGE_TEXT = 'Error: No hay suficiente stock disponible para completar la venta.';
      END IF;


      -- Descontar la cantidad solicitada del lote actual
      IF v_cantidadRestante <= v_lote_cantidadDisponible THEN
          UPDATE lote_producto
          SET cantidadDespachada = cantidadDespachada + v_cantidadRestante
          WHERE id = v_lote_id;


          -- Toda la cantidad restante ha sido cubierta
          SET v_cantidadRestante = 0;
      ELSE
          -- Usar todo el stock disponible en este lote y continuar con el siguiente lote
          UPDATE lote_producto
          SET cantidadDespachada = cantidadReabastecida
          WHERE id = v_lote_id;


          -- Reducir la cantidad restante por la cantidad utilizada del lote
          SET v_cantidadRestante = v_cantidadRestante - v_lote_cantidadDisponible;
      END IF;
  END WHILE;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registrar_venta_y_descuento` (IN `p_fechaVenta` DATE, IN `p_total` DECIMAL(10,2), IN `p_id_cliente` BIGINT(20), IN `p_id_empleado` BIGINT(20), IN `p_tokenSIN` BIGINT(20), IN `p_detalle` JSON, OUT `p_resultado` VARCHAR(100), OUT `p_status` INT)   main_block: BEGIN  -- Añadida etiqueta al bloque principal
  DECLARE v_id_venta BIGINT(20);
  DECLARE i INT DEFAULT 0;
  DECLARE v_cantidad INT;
  DECLARE v_precioUnitario DECIMAL(10,2);
  DECLARE v_id_producto INT;
  DECLARE v_stockDisponible INT;

  -- Manejador de excepciones
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
      ROLLBACK;
      SET p_resultado = 'Error: No se pudo completar la venta. Transacción revertida.';
      SET p_status = 400;
  END;

  START TRANSACTION;

  -- Validar cantidades de los productos en el JSON detalle
  WHILE JSON_LENGTH(p_detalle) > i DO
      SET v_cantidad = JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].cantidad'));
      SET v_id_producto = JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].id_producto'));

      -- Obtener la cantidad disponible (cantidadStock)
      SELECT cantidadStock
      INTO v_stockDisponible
      FROM producto WHERE id = v_id_producto;

      -- Verificar si la cantidad solicitada supera el stock disponible
      IF v_cantidad > v_stockDisponible THEN
          ROLLBACK;
          SET p_resultado = CONCAT('Error: Stock insuficiente para el producto con ID: ', v_id_producto);
          SET p_status = 400;
          LEAVE main_block; -- Ahora hace referencia a la etiqueta
      END IF;

      SET i = i + 1;
  END WHILE;

  -- Insertar la venta en la tabla 'venta'
  INSERT INTO venta (fechaVenta, total, id_cliente)
  VALUES (p_fechaVenta, p_total, p_id_cliente);

  -- Obtener el ID de la venta recién insertada
  SET v_id_venta = LAST_INSERT_ID();

  -- Reiniciar índice para procesar los detalles
  SET i = 0;

  -- Procesar cada producto en el JSON detalle
  WHILE JSON_LENGTH(p_detalle) > i DO
      SET v_cantidad = JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].cantidad'));
      SET v_precioUnitario = JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].precioUnitario'));
      SET v_id_producto = JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].id_producto'));


      -- Insertar en detalle_venta
      INSERT INTO detalle_venta (cantidad, precioUnitario, id_venta, id_producto)
      VALUES (v_cantidad, v_precioUnitario, v_id_venta, v_id_producto);

      -- Descontar del inventario
      CALL descontar_inventario(v_id_producto, v_cantidad);

      SET i = i + 1;
  END WHILE;

  COMMIT;

  SET p_resultado = 'Venta registrada exitosamente';
  SET p_status = 200;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registro_Compra_y_Detalle_mas_Lote_update_Product` (IN `p_fechaCompra` DATE, IN `p_total` DECIMAL(10,2), IN `p_id_proveedor` BIGINT(20) UNSIGNED, IN `p_detalle` JSON, IN `p_fechaVencimiento` DATE, OUT `p_resultado` VARCHAR(100), OUT `p_status` INT)   BEGIN
DECLARE v_id_compra BIGINT(20) UNSIGNED;
DECLARE i INT DEFAULT 0;
DECLARE v_cantidad INT;
DECLARE v_precioUnitario DECIMAL(10,2);
DECLARE v_precioVenta DECIMAL(10,2);
DECLARE v_id_producto INT;
DECLARE v_numLote INT;
DECLARE v_cantidadStock INT;

DECLARE v_validProveedor INT;
DECLARE v_productExists INT;
DECLARE v_error BOOLEAN DEFAULT FALSE;

-- Manejador de excepciones
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
    ROLLBACK;
    SET p_resultado = 'Error: No se pudo completar el registro. Transacción revertida.';
    SET p_status = 400;
END;

    -- Validar que el total de la compra sea positivo
    IF p_total <= 0 THEN
        SET p_resultado = 'Error: El total de la compra debe ser mayor a cero.';
        SET p_status = 400;
        SET v_error = TRUE;
    END IF;
    -- Validar que el proveedor exista
    IF NOT v_error THEN
        SELECT COUNT(*) INTO v_validProveedor FROM proveedor WHERE id = p_id_proveedor;
        IF v_validProveedor = 0 THEN
            SET p_resultado = 'Error: El proveedor especificado no existe.';
            SET p_status = 404;
            SET v_error = TRUE;
        END IF;
    END IF;
    -- Validar que la fecha de vencimiento sea futura
    IF NOT v_error AND p_fechaVencimiento <= CURDATE() THEN
        SET p_resultado = 'Error: La fecha de vencimiento debe ser posterior a la fecha actual.';
        SET p_status = 400;
        SET v_error = TRUE;
    END IF;
    IF v_error THEN
        ROLLBACK;
    END IF;

    -- Iniciar la transacción
    START TRANSACTION;

        -- Insertar la compra
        INSERT INTO compra (fechaCompra, total, id_proveedor)
        VALUES (p_fechaCompra, p_total, p_id_proveedor);

        -- Obtener el ID de la compra recién insertada
        SET v_id_compra = LAST_INSERT_ID();

        -- Obtener el último número de lote e incrementarlo
        SET v_numLote = COALESCE((SELECT MAX(CAST(numLote AS SIGNED)) FROM lote_producto), 0) + 1;

        -- Iterar sobre los detalles proporcionados (usando un JSON de detalles)
        WHILE i < JSON_LENGTH(p_detalle) DO
            SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].cantidad')));
            SET v_precioUnitario = JSON_UNQUOTE(JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].precioUnitario')));
            SET v_precioVenta = JSON_UNQUOTE(JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].precioVenta')));
            SET v_id_producto = JSON_UNQUOTE(JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].id_producto')));

            -- Validar que los campos necesarios sean positivos
            IF v_cantidad <= 0 OR v_precioUnitario <= 0 OR v_precioVenta <= 0 THEN
                SET p_resultado = CONCAT('Error: Cantidad, precio unitario y precio de venta deben ser mayores a cero (detalle index ', i, ').');
                SET p_status = 400;
                ROLLBACK;
            END IF;
            -- Validar que el producto exista
            SELECT COUNT(*) INTO v_productExists FROM producto WHERE id = v_id_producto;
            IF v_productExists = 0 THEN
                SET p_resultado = CONCAT('Error: El producto con ID ', v_id_producto, ' no existe (detalle index ', i, ').');
                SET p_status = 404;
                ROLLBACK;
            END IF;

            -- Seleccionar el stock actual del producto
            SELECT cantidadStock INTO v_cantidadStock
            FROM producto
            WHERE id = v_id_producto;

            -- Insertar el detalle de la compra en 'detalle_compra'
            INSERT INTO detalle_compra (cantidad, precioUnitario, id_compra, id_producto)
            VALUES (v_cantidad, v_precioUnitario, v_id_compra, v_id_producto);
            -- Verificar si la inserción fue exitosa
            IF ROW_COUNT() = 0 THEN
                SELECT 'Error en INSERT detalle_compra', v_id_producto, v_cantidad, v_precioUnitario;
                ROLLBACK;
            END IF;

            -- Insertar el lote en 'lote_producto' linea 108 - 115
            INSERT INTO lote_producto (numLote, fechaReabastecimiento, cantidadReabastecida, fechaVencimiento, precioCompra, precioVenta, id_producto)
            VALUES (v_numLote, p_fechaCompra, v_cantidad, p_fechaVencimiento, v_precioUnitario, v_precioVenta, v_id_producto);
             -- Verificar si la inserción fue exitosa
            IF ROW_COUNT() = 0 THEN
                SELECT 'Error en INSERT lote_producto', v_numLote, p_fechaCompra, v_cantidad, p_fechaVencimiento, v_precioUnitario, v_precioVenta, v_id_producto;
                ROLLBACK;
            END IF;            

            -- Actualizar el stock del producto en la tabla 'producto'
            UPDATE producto
            SET cantidadStock = v_cantidadStock + v_cantidad
            WHERE id = v_id_producto;

            -- Incrementar el índice para el siguiente elemento del JSON
            SET i = i + 1;
        END WHILE;

-- Verificar si las inserciones fueron exitosas
IF ROW_COUNT() > 0 THEN
    SET p_resultado = 'Registro de compras completado exitosamente';
    SET p_status = 201;
    COMMIT;
ELSE
    SET p_resultado = 'Error: No se pudo completar el registro de la compra o los detalles';
    SET p_status = 400;
    ROLLBACK;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registro_persona_empleado` (IN `u_username` VARCHAR(100), IN `u_password` VARCHAR(255), IN `u_rol` ENUM('admin','user','guest'), IN `p_ci` VARCHAR(15), IN `p_ciExpedit` VARCHAR(2), IN `p_ciComplement` INT, IN `p_nombre` VARCHAR(100), IN `p_app` VARCHAR(100), IN `p_apm` VARCHAR(100), IN `p_sexo` CHAR(1), IN `p_fnaci` DATE, IN `p_direccion` VARCHAR(200), IN `p_telefono` VARCHAR(15), IN `p_email` VARCHAR(100), IN `e_idtipo` BIGINT, IN `e_idcargo` BIGINT, IN `e_fing` VARCHAR(255), IN `e_salario` INT, OUT `p_resultado` VARCHAR(100), OUT `p_status` INT)   BEGIN
   DECLARE v_id_persona BIGINT;
   DECLARE v_id_empleado BIGINT;


   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       ROLLBACK;
       SET p_resultado = 'Error: No se pudo completar el registro. Transacción revertida.';
       SET p_status = 400;
   END;


   -- Verificar si ya existe un usuario con el username proporcionado
   IF EXISTS (SELECT 1 FROM usuario WHERE username = u_username) THEN
       SET p_resultado = 'Error: Ya existe un usuario con ese nombre.';
       SET p_status = 400;
   ELSE
       START TRANSACTION;


        -- Verificar si ya existe una persona con el CI proporcionado
       SELECT id INTO v_id_persona FROM persona WHERE ci = p_ci;


       -- Si no existe, insertar la persona
       IF v_id_persona IS NULL THEN
           -- Insertar persona
           INSERT INTO persona (ci, ciExpedit, ciComplement, nombre, app, apm, sexo, fnaci, direccion, telefono, email, state)
           VALUES (p_ci, p_ciExpedit, p_ciComplement, p_nombre, p_app, p_apm, p_sexo, p_fnaci, p_direccion, p_telefono, p_email, 1);
           SET v_id_persona = LAST_INSERT_ID();
       END IF;


       -- Insertar empleado
       INSERT INTO empleado (idtipo, idcargo, salario, fing, idper)
       VALUES (e_idtipo, e_idcargo, e_salario, e_fing, v_id_persona);
      
       SET v_id_empleado = LAST_INSERT_ID();


       -- Insertar usuario
       INSERT INTO usuario (username, passwordHash, rol, estado, id_empleado)
       VALUES (u_username, u_password, u_rol, 'activo', v_id_empleado);
      
       IF ROW_COUNT() > 0 THEN
           SET p_resultado = 'Registro completado exitosamente';
           SET p_status = 201;
           COMMIT;
       ELSE
           SET p_resultado = 'Error: No se pudo completar el registro';
           SET p_status = 400;
           ROLLBACK;
       END IF;
   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registro_persona_proveedor` (IN `p_ci` VARCHAR(15), IN `p_ciExpedit` VARCHAR(2), IN `p_ciComplement` INT, IN `p_nombre` VARCHAR(100), IN `p_app` VARCHAR(100), IN `p_apm` VARCHAR(100), IN `p_sexo` CHAR(1), IN `p_fnaci` DATE, IN `p_direccion` VARCHAR(200), IN `p_telefono` VARCHAR(15), IN `p_email` VARCHAR(100), IN `pr_empresa` VARCHAR(100), IN `pr_nit` VARCHAR(20), IN `pr_telefonoEmpresa` VARCHAR(15), IN `pr_direccionEmpresa` VARCHAR(200), OUT `p_resultado` VARCHAR(100), OUT `p_status` INT)   BEGIN
   DECLARE v_id_persona BIGINT;


   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       ROLLBACK;
       SET p_resultado = 'Error: No se pudo insertar el proveedor. Transacción revertida.';
       SET p_status = 400;
   END;


   -- Verificar si ya existe un usuario con el username proporcionado
   IF EXISTS (SELECT 1 FROM proveedor WHERE empresa = pr_empresa) THEN
       SET p_resultado = 'Error: Ya existe un proveedor con ese nombre.';
       SET p_status = 400;
   ELSE
  
       START TRANSACTION;


       -- Verificar si ya existe una persona con el CI proporcionado
       SELECT id INTO v_id_persona FROM persona WHERE ci = p_ci;


       -- Si no existe, insertar la persona
       IF v_id_persona IS NULL THEN
           INSERT INTO persona (ci, ciExpedit, ciComplement, nombre, app, apm, sexo, fnaci, direccion, telefono, email, state)
           VALUES (p_ci, p_ciExpedit, p_ciComplement, p_nombre, p_app, p_apm, p_sexo, p_fnaci, p_direccion, p_telefono, p_email, 1);
           SET v_id_persona = LAST_INSERT_ID();
       END IF;


       -- Insertar proveedor
       INSERT INTO proveedor (empresa, nit, telefonoEmpresa, direccionEmpresa, id_persona)
       VALUES (pr_empresa, pr_nit, pr_telefonoEmpresa, pr_direccionEmpresa, v_id_persona);


       IF ROW_COUNT() > 0 THEN
           SET p_resultado = 'Proveedor registrado exitosamente.';
           SET p_status = 201;
           COMMIT;
       ELSE
           SET p_resultado = 'Error: No se pudo insertar el proveedor.';
           SET p_status = 400;
           ROLLBACK;
       END IF;
   END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registro_producto` (IN `p_nombre` VARCHAR(100), IN `p_descripcion` TEXT, IN `p_cantidadStock` INT, IN `p_fechaIngreso` DATE, IN `p_unidadMedida` VARCHAR(20), IN `p_codigoProducto` VARCHAR(50), IN `p_idProveedor` BIGINT, IN `p_idCategoria` BIGINT, IN `p_state` INT, OUT `p_resultado` VARCHAR(100), OUT `p_status` INT)   BEGIN
   DECLARE v_proveedorExiste INT;
   DECLARE v_codigoProductoExiste INT;


   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       ROLLBACK;
       SET p_resultado = 'Error: No se pudo completar el registro. Transacción revertida.';
       SET p_status = 400;
   END;


   -- Verificar si el proveedor existe
   SELECT COUNT(*) INTO v_proveedorExiste
   FROM proveedor
   WHERE id = p_idProveedor;


   IF v_proveedorExiste = 0 THEN
       SET p_resultado = 'Error: El proveedor no existe.';
       SET p_status = 400;
   ELSE
       -- Verificar si el código de producto ya existe
       SELECT COUNT(*) INTO v_codigoProductoExiste
       FROM producto
       WHERE codigoProducto = p_codigoProducto;


       IF v_codigoProductoExiste > 0 THEN
           SET p_resultado = 'Error: El código de producto ya existe.';
           SET p_status = 400;
       ELSE
           START TRANSACTION;


           -- Insertar el producto
           INSERT INTO producto (nombre,descripcion,cantidadStock,fechaIngreso,unidadMedida,codigoProducto,id_proveedor,id_categoria,state)
           VALUES (p_nombre,p_descripcion,p_cantidadStock,p_fechaIngreso,p_unidadMedida,p_codigoProducto,p_idProveedor,p_idCategoria,p_state);


           -- Verificar si la inserción fue exitosa
           IF ROW_COUNT() > 0 THEN
               SET p_resultado = 'Producto registrado exitosamente.';
               SET p_status = 201;
               COMMIT;
           ELSE
               SET p_resultado = 'Error: No se pudo registrar el producto.';
               SET p_status = 400;
               ROLLBACK;
           END IF;
       END IF;
   END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `almacen`
--

CREATE TABLE `almacen` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `direccion` varchar(255) NOT NULL,
  `matriz` tinyint(4) NOT NULL,
  `capacidad` bigint(20) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `categoria`
--

CREATE TABLE `categoria` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `descripcion` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `categoria`
--

INSERT INTO `categoria` (`id`, `nombre`, `descripcion`) VALUES
(1, 'categoria 1', 'descripcion categoria 1'),
(2, 'Categoria 2', 'Descipcion 2'),
(3, 'Categoria 3', 'Descripcion 3');

-- --------------------------------------------------------

--
-- Table structure for table `cliente`
--

CREATE TABLE `cliente` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `ci` int(11) NOT NULL,
  `nit` int(11) DEFAULT NULL,
  `typeCnFact` tinyint(1) NOT NULL,
  `state` tinyint(1) NOT NULL,
  `id_persona` bigint(20) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `combo`
--

CREATE TABLE `combo` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `descuento` decimal(5,2) DEFAULT NULL,
  `precioFinal` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `combo_producto`
--

CREATE TABLE `combo_producto` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `cantidad` decimal(10,2) NOT NULL,
  `id_combo` bigint(20) UNSIGNED DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `compra`
--

CREATE TABLE `compra` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `fechaCompra` date NOT NULL,
  `total` decimal(10,2) DEFAULT NULL,
  `id_proveedor` bigint(20) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `detalle_compra`
--

CREATE TABLE `detalle_compra` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precioUnitario` decimal(10,2) DEFAULT NULL,
  `id_compra` bigint(20) UNSIGNED DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `detalle_venta`
--

CREATE TABLE `detalle_venta` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precioUnitario` decimal(10,2) DEFAULT NULL,
  `id_venta` bigint(20) UNSIGNED DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `id_lote_producto` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `empleado`
--

CREATE TABLE `empleado` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `idtipo` bigint(20) UNSIGNED NOT NULL,
  `idcargo` bigint(20) UNSIGNED NOT NULL,
  `salario` int(11) NOT NULL,
  `idper` bigint(20) UNSIGNED NOT NULL,
  `fing` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `inventario`
--

CREATE TABLE `inventario` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `cantidadStock` int(11) NOT NULL,
  `fechaInventario` date DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL,
  `id_almacen` bigint(20) UNSIGNED DEFAULT NULL,
  `cantidadReservada` int(11) NOT NULL,
  `cantidadDespachada` int(11) NOT NULL,
  `fechaIngreso` date DEFAULT NULL,
  `fechaSalida` date DEFAULT NULL,
  `idLote` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `lote_producto`
--

CREATE TABLE `lote_producto` (
  `id` int(11) NOT NULL,
  `numLote` varchar(50) NOT NULL,
  `fechaReabastecimiento` date NOT NULL,
  `cantidadReabastecida` int(11) NOT NULL,
  `fechaVencimiento` date DEFAULT NULL,
  `precioCompra` decimal(10,2) DEFAULT NULL,
  `precioVenta` decimal(10,2) DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `materiales_servicio`
--

CREATE TABLE `materiales_servicio` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `cantidadRequerida` decimal(10,2) DEFAULT NULL,
  `costoUnitario` decimal(10,2) DEFAULT NULL,
  `id_servicio` bigint(20) UNSIGNED DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `orden_servicio`
--

CREATE TABLE `orden_servicio` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `fechaSolicitud` date DEFAULT NULL,
  `fechaEntrega` date DEFAULT NULL,
  `cantidad` decimal(10,2) DEFAULT NULL,
  `precioTotal` decimal(10,2) DEFAULT NULL,
  `id_cliente` bigint(20) UNSIGNED DEFAULT NULL,
  `id_servicio` bigint(20) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `persona`
--

CREATE TABLE `persona` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `ci` varchar(15) NOT NULL,
  `ciExpedit` varchar(2) NOT NULL,
  `ciComplement` int(5) NOT NULL,
  `nombre` varchar(100) DEFAULT NULL,
  `app` varchar(100) DEFAULT NULL,
  `apm` varchar(100) DEFAULT NULL,
  `sexo` char(1) DEFAULT NULL,
  `fnaci` date DEFAULT NULL,
  `direccion` varchar(200) DEFAULT NULL,
  `telefono` varchar(15) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `state` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `producto`
--

CREATE TABLE `producto` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `cantidadStock` int(11) NOT NULL,
  `fechaIngreso` date DEFAULT NULL,
  `unidadMedida` varchar(20) DEFAULT NULL,
  `codigoProducto` varchar(50) NOT NULL,
  `state` int(11) NOT NULL,
  `id_proveedor` bigint(20) UNSIGNED DEFAULT NULL,
  `id_categoria` bigint(20) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `proveedor`
--

CREATE TABLE `proveedor` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `empresa` varchar(100) NOT NULL,
  `nit` varchar(20) NOT NULL,
  `telefonoEmpresa` varchar(15) DEFAULT NULL,
  `direccionEmpresa` varchar(200) DEFAULT NULL,
  `id_persona` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `servicio`
--

CREATE TABLE `servicio` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `precioBase` decimal(10,2) DEFAULT NULL,
  `unidadCobro` varchar(50) DEFAULT NULL,
  `duracionEstimada` varchar(50) DEFAULT NULL,
  `id_empleado` bigint(20) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `usuario`
--

CREATE TABLE `usuario` (
  `id` bigint(20) NOT NULL,
  `username` varchar(100) NOT NULL,
  `passwordHash` varchar(255) NOT NULL,
  `rol` enum('admin','user','guest') NOT NULL DEFAULT 'user',
  `estado` enum('activo','inactivo') NOT NULL DEFAULT 'activo',
  `fechaCreacion` timestamp NOT NULL DEFAULT current_timestamp(),
  `id_empleado` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `venta`
--

CREATE TABLE `venta` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `fechaVenta` date NOT NULL,
  `total` decimal(10,2) DEFAULT NULL,
  `tokenSIM` varchar(255) DEFAULT NULL,
  `id_cliente` bigint(20) UNSIGNED DEFAULT NULL,
  `id_empleado` bigint(20) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `venta_combo`
--

CREATE TABLE `venta_combo` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `precioCombo` decimal(10,2) DEFAULT NULL,
  `cantidad` int(11) NOT NULL,
  `id_venta` bigint(20) UNSIGNED DEFAULT NULL,
  `id_combo` bigint(20) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `almacen`
--
ALTER TABLE `almacen`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `categoria`
--
ALTER TABLE `categoria`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cliente`
--
ALTER TABLE `cliente`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_0889ef3595b17ad5eeb6b7cf908` (`id_persona`);

--
-- Indexes for table `combo`
--
ALTER TABLE `combo`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `combo_producto`
--
ALTER TABLE `combo_producto`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_85c83840b90c55bc6bcf92980df` (`id_combo`),
  ADD KEY `FK_3e7f55226a1547011162a582af4` (`id_producto`);

--
-- Indexes for table `compra`
--
ALTER TABLE `compra`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_ad08d34153edea2d6ea537011da` (`id_proveedor`);

--
-- Indexes for table `detalle_compra`
--
ALTER TABLE `detalle_compra`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_2edc66f170849a8bd0b91b1ffb1` (`id_compra`),
  ADD KEY `FK_efd9f434da94e4366b54dd6474c` (`id_producto`);

--
-- Indexes for table `detalle_venta`
--
ALTER TABLE `detalle_venta`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_175fd103d258655939b7fa81530` (`id_venta`),
  ADD KEY `FK_46042990544850e9e972c1961e8` (`id_producto`);

--
-- Indexes for table `empleado`
--
ALTER TABLE `empleado`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_b6d8e60c904fac8e603a1ba4ef1` (`idper`);

--
-- Indexes for table `inventario`
--
ALTER TABLE `inventario`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_467c42d673222f61151a26570fa` (`id_producto`),
  ADD KEY `FK_87d17af32f9bcd0376adb35c467` (`id_almacen`);

--
-- Indexes for table `lote_producto`
--
ALTER TABLE `lote_producto`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_004eaebf224e376c82ead3979b2` (`id_producto`);

--
-- Indexes for table `materiales_servicio`
--
ALTER TABLE `materiales_servicio`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_da8e636a3ca1f4535c4246ed7c6` (`id_servicio`),
  ADD KEY `FK_391c3b867b3827a4141fbdda2ab` (`id_producto`);

--
-- Indexes for table `orden_servicio`
--
ALTER TABLE `orden_servicio`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_4dbada967973ee9e17b4ef360ce` (`id_cliente`),
  ADD KEY `FK_b57730a5ae005e01ac2a524f68a` (`id_servicio`);

--
-- Indexes for table `persona`
--
ALTER TABLE `persona`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `IDX_5cd57db9cc1b133cacb180b29e` (`ci`);

--
-- Indexes for table `producto`
--
ALTER TABLE `producto`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `IDX_330f84bc5b342017cb02d3b813` (`codigoProducto`),
  ADD KEY `FK_594d83bcc50933f539fc7280561` (`id_proveedor`),
  ADD KEY `FK_e87a319f3da1b6da5fedd1988be` (`id_categoria`);

--
-- Indexes for table `proveedor`
--
ALTER TABLE `proveedor`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_e9dad034a00415271e9c67903c8` (`id_persona`);

--
-- Indexes for table `servicio`
--
ALTER TABLE `servicio`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_197e415a62ea4d1fec393164470` (`id_empleado`);

--
-- Indexes for table `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `IDX_6ccff37176a6978449a99c82e1` (`username`),
  ADD KEY `FK_5dcacfc0a34838fb77c0c905336` (`id_empleado`);

--
-- Indexes for table `venta`
--
ALTER TABLE `venta`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_777d3faa95ab9ee43830dc14b8b` (`id_cliente`),
  ADD KEY `FK_e3323cf2e33b11e14e7984b6413` (`id_empleado`);

--
-- Indexes for table `venta_combo`
--
ALTER TABLE `venta_combo`
  ADD PRIMARY KEY (`id`),
  ADD KEY `FK_b746bb8d154c374035a0fd99a02` (`id_venta`),
  ADD KEY `FK_e9e142de9618d67c11445e05315` (`id_combo`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `almacen`
--
ALTER TABLE `almacen`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `categoria`
--
ALTER TABLE `categoria`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `cliente`
--
ALTER TABLE `cliente`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `combo`
--
ALTER TABLE `combo`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `combo_producto`
--
ALTER TABLE `combo_producto`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `compra`
--
ALTER TABLE `compra`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=115;

--
-- AUTO_INCREMENT for table `detalle_compra`
--
ALTER TABLE `detalle_compra`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=133;

--
-- AUTO_INCREMENT for table `detalle_venta`
--
ALTER TABLE `detalle_venta`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `empleado`
--
ALTER TABLE `empleado`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `inventario`
--
ALTER TABLE `inventario`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `lote_producto`
--
ALTER TABLE `lote_producto`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `materiales_servicio`
--
ALTER TABLE `materiales_servicio`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `orden_servicio`
--
ALTER TABLE `orden_servicio`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `persona`
--
ALTER TABLE `persona`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `producto`
--
ALTER TABLE `producto`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `proveedor`
--
ALTER TABLE `proveedor`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `servicio`
--
ALTER TABLE `servicio`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `usuario`
--
ALTER TABLE `usuario`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `venta`
--
ALTER TABLE `venta`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `venta_combo`
--
ALTER TABLE `venta_combo`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `cliente`
--
ALTER TABLE `cliente`
  ADD CONSTRAINT `FK_0889ef3595b17ad5eeb6b7cf908` FOREIGN KEY (`id_persona`) REFERENCES `persona` (`id`) ON DELETE SET NULL ON UPDATE NO ACTION;

--
-- Constraints for table `combo_producto`
--
ALTER TABLE `combo_producto`
  ADD CONSTRAINT `FK_3e7f55226a1547011162a582af4` FOREIGN KEY (`id_producto`) REFERENCES `producto` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_85c83840b90c55bc6bcf92980df` FOREIGN KEY (`id_combo`) REFERENCES `combo` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Constraints for table `compra`
--
ALTER TABLE `compra`
  ADD CONSTRAINT `FK_ad08d34153edea2d6ea537011da` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedor` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Constraints for table `detalle_compra`
--
ALTER TABLE `detalle_compra`
  ADD CONSTRAINT `FK_2edc66f170849a8bd0b91b1ffb1` FOREIGN KEY (`id_compra`) REFERENCES `compra` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_efd9f434da94e4366b54dd6474c` FOREIGN KEY (`id_producto`) REFERENCES `producto` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Constraints for table `detalle_venta`
--
ALTER TABLE `detalle_venta`
  ADD CONSTRAINT `FK_175fd103d258655939b7fa81530` FOREIGN KEY (`id_venta`) REFERENCES `venta` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_46042990544850e9e972c1961e8` FOREIGN KEY (`id_producto`) REFERENCES `producto` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Constraints for table `empleado`
--
ALTER TABLE `empleado`
  ADD CONSTRAINT `FK_b6d8e60c904fac8e603a1ba4ef1` FOREIGN KEY (`idper`) REFERENCES `persona` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Constraints for table `inventario`
--
ALTER TABLE `inventario`
  ADD CONSTRAINT `FK_467c42d673222f61151a26570fa` FOREIGN KEY (`id_producto`) REFERENCES `producto` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_87d17af32f9bcd0376adb35c467` FOREIGN KEY (`id_almacen`) REFERENCES `almacen` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Constraints for table `lote_producto`
--
ALTER TABLE `lote_producto`
  ADD CONSTRAINT `FK_004eaebf224e376c82ead3979b2` FOREIGN KEY (`id_producto`) REFERENCES `producto` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Constraints for table `materiales_servicio`
--
ALTER TABLE `materiales_servicio`
  ADD CONSTRAINT `FK_391c3b867b3827a4141fbdda2ab` FOREIGN KEY (`id_producto`) REFERENCES `producto` (`id`) ON DELETE SET NULL ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_da8e636a3ca1f4535c4246ed7c6` FOREIGN KEY (`id_servicio`) REFERENCES `servicio` (`id`) ON DELETE SET NULL ON UPDATE NO ACTION;

--
-- Constraints for table `orden_servicio`
--
ALTER TABLE `orden_servicio`
  ADD CONSTRAINT `FK_4dbada967973ee9e17b4ef360ce` FOREIGN KEY (`id_cliente`) REFERENCES `cliente` (`id`) ON DELETE SET NULL ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_b57730a5ae005e01ac2a524f68a` FOREIGN KEY (`id_servicio`) REFERENCES `servicio` (`id`) ON DELETE SET NULL ON UPDATE NO ACTION;

--
-- Constraints for table `producto`
--
ALTER TABLE `producto`
  ADD CONSTRAINT `FK_594d83bcc50933f539fc7280561` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedor` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_e87a319f3da1b6da5fedd1988be` FOREIGN KEY (`id_categoria`) REFERENCES `categoria` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Constraints for table `proveedor`
--
ALTER TABLE `proveedor`
  ADD CONSTRAINT `FK_e9dad034a00415271e9c67903c8` FOREIGN KEY (`id_persona`) REFERENCES `persona` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Constraints for table `servicio`
--
ALTER TABLE `servicio`
  ADD CONSTRAINT `FK_197e415a62ea4d1fec393164470` FOREIGN KEY (`id_empleado`) REFERENCES `empleado` (`id`) ON DELETE SET NULL ON UPDATE NO ACTION;

--
-- Constraints for table `usuario`
--
ALTER TABLE `usuario`
  ADD CONSTRAINT `FK_5dcacfc0a34838fb77c0c905336` FOREIGN KEY (`id_empleado`) REFERENCES `empleado` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Constraints for table `venta`
--
ALTER TABLE `venta`
  ADD CONSTRAINT `FK_777d3faa95ab9ee43830dc14b8b` FOREIGN KEY (`id_cliente`) REFERENCES `cliente` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_e3323cf2e33b11e14e7984b6413` FOREIGN KEY (`id_empleado`) REFERENCES `empleado` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;

--
-- Constraints for table `venta_combo`
--
ALTER TABLE `venta_combo`
  ADD CONSTRAINT `FK_b746bb8d154c374035a0fd99a02` FOREIGN KEY (`id_venta`) REFERENCES `venta` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_e9e142de9618d67c11445e05315` FOREIGN KEY (`id_combo`) REFERENCES `combo` (`id`) ON DELETE CASCADE ON UPDATE NO ACTION;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
