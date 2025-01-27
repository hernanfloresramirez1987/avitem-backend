-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jan 27, 2025 at 12:28 PM
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `registrar_venta_y_descuento` (IN `p_fechaVenta` DATE, IN `p_total` DECIMAL(10,2), IN `p_id_cliente` BIGINT(20), IN `p_id_empleado` BIGINT(20), IN `p_confactura` INT, IN `p_tokenSIN` VARCHAR(255), IN `p_detalle` JSON, OUT `p_resultado` VARCHAR(100), OUT `p_status` INT)   BEGIN  -- Añadida etiqueta al bloque principal
  DECLARE v_id_venta BIGINT(20);
  DECLARE i INT DEFAULT 0;
  DECLARE v_cantidad INT;
  DECLARE v_precioUnitario DECIMAL(10,2);
  DECLARE v_id_producto INT;
  DECLARE v_stockDisponible INT;
  DECLARE v_productExists INT ;
  DECLARE v_stocktotal INT;
  DECLARE v_cantidadStock INT;
  DECLARE v_id_almacen INT;

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
        SET v_precioUnitario = JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].precioUnitario'));

        -- Obtener la cantidad disponible (cantidadStock)
        SELECT cantidadStock
        INTO v_stockDisponible
        FROM producto WHERE id = v_id_producto;

        -- Verificar si la cantidad solicitada supera el stock disponible
        IF v_cantidad > v_stockDisponible THEN
            ROLLBACK;
            SET p_resultado = CONCAT('Error: Stock insuficiente para el producto con ID: ', v_id_producto);
            SET p_status = 400;
        END IF;

        SET i = i + 1;
    END WHILE;

    -- Insertar la venta en la tabla 'venta'
    INSERT INTO venta (fechaVenta, total, tokenSIM, id_cliente, id_empleado, confactura)
    VALUES (p_fechaVenta, p_total, p_tokenSIN, p_id_cliente, p_id_empleado, p_confactura);
  
    -- Verificar si la inserción fue exitosa
    IF ROW_COUNT() = 0 THEN
        SELECT 'Error en INSERT venta', v_id_producto, v_cantidad, v_precioUnitario;
        ROLLBACK;
    END IF;

    -- Obtener el ID de la venta recién insertada
    SET v_id_venta = LAST_INSERT_ID();

    -- Reiniciar índice para procesar los detalles
    SET i = 0;
    -- Procesar cada producto en el JSON detalle
    WHILE i < JSON_LENGTH(p_detalle) DO
            SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].cantidad')));
            SET v_precioUnitario = JSON_UNQUOTE(JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].precioUnitario')));
            SET v_id_producto = JSON_UNQUOTE(JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].id_producto')));
            SET v_id_almacen = JSON_UNQUOTE(JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].id_almacen')));

           -- Validar que los campos necesarios sean positivos
           IF v_cantidad <= 0 OR v_precioUnitario <= 0 THEN
               SET p_resultado = CONCAT('Error: Cantidad o Precio unitario deben ser mayores a cero (detalle index ', i, ').');
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

           UPDATE producto
           SET cantidadStock = v_cantidadStock - v_cantidad
           WHERE id = v_id_producto;


            -- Insertar en detalle_venta
            INSERT INTO detalle_venta (cantidad, precioUnitario, id_venta, id_producto)
            VALUES (v_cantidad, v_precioUnitario, v_id_venta, v_id_producto);

            -- SELECT cantidadStock INTO v_stocktotal FROM producto
            -- WHERE id = v_id_producto;

            -- SET v_stocktotal = v_stocktotal - v_cantidad;

            INSERT INTO inventario (cantidadStock, fechaInventario, id_producto, id_almacen, cantidadReservada, cantidadDespachada, fechaIngreso, fechaSalida, idLote)
            VALUES ((v_cantidadStock - v_cantidad), CURRENT_DATE, v_id_producto, v_id_almacen, v_cantidad, v_cantidad, CURRENT_DATE, CURRENT_DATE, 0);
            -- Verificar si la inserción fue exitosa
            IF ROW_COUNT() = 0 THEN
               SELECT 'Error en INSERT inventory', v_numLote, v_cantidadStock, p_fechaCompra, v_id_producto, v_id_almacen, v_cantidad, v_precioUnitario, v_precioVenta, v_id_producto;
               ROLLBACK;
            END IF;

           -- Incrementar el índice para el siguiente elemento del JSON
           SET i = i + 1;
       END WHILE;

    -- Verificar si las inserciones fueron exitosas
    IF ROW_COUNT() > 0 THEN
        SET p_resultado = 'Registro de ventas completado exitosamente';
        SET p_status = 201;
        COMMIT;
    ELSE
        SET p_resultado = 'Error: No se pudo completar el registro de la venta o los detalles';
        SET p_status = 400;
        ROLLBACK;
    END IF;
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
DECLARE v_id_almacen INT;
DECLARE v_stocktotal INT;
DECLARE v_id_lote INT;


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
            SET v_id_almacen = JSON_UNQUOTE(JSON_EXTRACT(p_detalle, CONCAT('$[', i, '].id_almacen')));

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
        
           SET v_id_lote = LAST_INSERT_ID();

           -- Actualizar el stock del producto en la tabla 'producto'
           UPDATE producto
           SET cantidadStock = v_cantidadStock + v_cantidad
           WHERE id = v_id_producto;


            SELECT cantidadStock INTO v_stocktotal FROM producto
            WHERE id = v_id_producto;

            INSERT INTO inventario (cantidadStock, fechaInventario, id_producto, id_almacen, cantidadReservada, cantidadDespachada, fechaIngreso, fechaSalida, idLote)
            VALUES (v_stocktotal, CURRENT_DATE, v_id_producto, v_id_almacen, 0, 0, CURRENT_DATE, CURRENT_DATE, v_id_lote);
            -- Verificar si la inserción fue exitosa
            IF ROW_COUNT() = 0 THEN
               SELECT 'Error en INSERT inventory', v_numLote, v_cantidadStock, p_fechaCompra, v_id_producto, v_id_almacen, v_cantidad, v_precioUnitario, v_precioVenta, v_id_producto;
               ROLLBACK;
            END IF;





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

CREATE DEFINER=`root`@`localhost` PROCEDURE `registro_producto` (IN `p_nombre` VARCHAR(100), IN `p_descripcion` TEXT, IN `p_cantidadStock` INT, IN `p_fechaIngreso` DATE, IN `p_unidadMedida` VARCHAR(20), IN `p_codigoProducto` VARCHAR(50), IN `p_idProveedor` BIGINT, IN `p_idCategoria` BIGINT, IN `p_idColor` BIGINT, IN `p_state` INT, OUT `p_resultado` VARCHAR(100), OUT `p_status` INT)   BEGIN
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
           INSERT INTO producto (nombre,descripcion,cantidadStock,fechaIngreso,unidadMedida,codigoProducto,id_proveedor,id_categoria, id_color,state)
           VALUES (p_nombre,p_descripcion,p_cantidadStock,p_fechaIngreso,p_unidadMedida,p_codigoProducto,p_idProveedor,p_idCategoria, p_idColor, p_state);


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
  `capacidad` bigint(20) UNSIGNED DEFAULT NULL,
  `nombre` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `almacen`
--

INSERT INTO `almacen` (`id`, `direccion`, `matriz`, `capacidad`, `nombre`) VALUES
(1, 'Casa Matriz', 1, 1000000, 'Almacen Casas Matriz');

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
(1, 'Socalo Cromado', 'descripcion categoria 1'),
(2, 'Categoria Buchata Cromado', 'Descipcion 2'),
(3, 'Pivote', 'Descripcion 3');

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

--
-- Dumping data for table `cliente`
--

INSERT INTO `cliente` (`id`, `ci`, `nit`, `typeCnFact`, `state`, `id_persona`) VALUES
(2, 65467, NULL, 0, 1, 9);

-- --------------------------------------------------------

--
-- Table structure for table `color`
--

CREATE TABLE `color` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `code` varchar(10) DEFAULT NULL,
  `color` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `color`
--

INSERT INTO `color` (`id`, `code`, `color`) VALUES
(1, 'Nat', 'Natural'),
(2, 'Cha', 'Champan'),
(3, 'Neg', 'Negro'),
(4, 'Mad', 'Madera');

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

--
-- Dumping data for table `compra`
--

INSERT INTO `compra` (`id`, `fechaCompra`, `total`, `id_proveedor`) VALUES
(201, '2025-01-27', 426.00, 5);

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

--
-- Dumping data for table `detalle_compra`
--

INSERT INTO `detalle_compra` (`id`, `cantidad`, `precioUnitario`, `id_compra`, `id_producto`) VALUES
(216, 100, 2.50, 201, 17),
(217, 8, 12.00, 201, 19),
(218, 8, 10.00, 201, 21);

-- --------------------------------------------------------

--
-- Table structure for table `detalle_venta`
--

CREATE TABLE `detalle_venta` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `cantidad` int(11) NOT NULL,
  `precioUnitario` decimal(10,2) DEFAULT NULL,
  `id_venta` bigint(20) UNSIGNED DEFAULT NULL,
  `id_producto` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `detalle_venta`
--

INSERT INTO `detalle_venta` (`id`, `cantidad`, `precioUnitario`, `id_venta`, `id_producto`) VALUES
(68, 6, 90.00, 73, 17),
(69, 2, 27.50, 73, 19);

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

--
-- Dumping data for table `empleado`
--

INSERT INTO `empleado` (`id`, `idtipo`, `idcargo`, `salario`, `idper`, `fing`) VALUES
(5, 1, 1, 0, 9, '2025-01-16T01:24:56.443Z'),
(6, 3, 2, 12000, 9, '2025-01-16T01:24:56.443Z');

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

--
-- Dumping data for table `inventario`
--

INSERT INTO `inventario` (`id`, `cantidadStock`, `fechaInventario`, `id_producto`, `id_almacen`, `cantidadReservada`, `cantidadDespachada`, `fechaIngreso`, `fechaSalida`, `idLote`) VALUES
(58, 100, '2025-01-27', 17, 1, 0, 0, '2025-01-27', '2025-01-27', 85),
(59, 8, '2025-01-27', 19, 1, 0, 0, '2025-01-27', '2025-01-27', 86),
(60, 8, '2025-01-27', 21, 1, 0, 0, '2025-01-27', '2025-01-27', 87),
(61, 94, '2025-01-27', 17, NULL, 6, 6, '2025-01-27', '2025-01-27', 0),
(62, 6, '2025-01-27', 19, NULL, 2, 2, '2025-01-27', '2025-01-27', 0);

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

--
-- Dumping data for table `lote_producto`
--

INSERT INTO `lote_producto` (`id`, `numLote`, `fechaReabastecimiento`, `cantidadReabastecida`, `fechaVencimiento`, `precioCompra`, `precioVenta`, `id_producto`) VALUES
(85, '1', '2025-01-27', 100, '2025-12-31', 2.50, 5.00, 17),
(86, '1', '2025-01-27', 8, '2025-12-31', 12.00, 29.00, 19),
(87, '1', '2025-01-27', 8, '2025-12-31', 10.00, 20.00, 21);

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

--
-- Dumping data for table `persona`
--

INSERT INTO `persona` (`id`, `ci`, `ciExpedit`, `ciComplement`, `nombre`, `app`, `apm`, `sexo`, `fnaci`, `direccion`, `telefono`, `email`, `state`) VALUES
(6, '11111111', 'CB', 0, 'Aluminios', 'Mega', 'Alumn', 'M', '2024-01-05', 's/n direccion', '70735036', 'sinemail@gmail.com', 1),
(7, '22222222', 'CB', 0, 'sandy', 'vid', '', 'M', '2024-02-02', 'sin direccion', '70721528', 'sinemailsandy@gmail.com', 1),
(8, '33333333', 'ch', 0, 'Renhua', 'Boshi Aluminum Industry Co., Ltd', '', 'V', '2024-03-03', 'sin direccion ', '591 72398702', 'sinemailrenhua@gmail.com', 1),
(9, '10101010', 'CB', 0, 'Lidia', 'Avitem', '', 'M', '1990-05-05', 'Av de las Banderas', '591 72398702', 'lidiaavitem@gmail.com', 1);

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
  `id_categoria` bigint(20) UNSIGNED DEFAULT NULL,
  `id_color` bigint(20) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `producto`
--

INSERT INTO `producto` (`id`, `nombre`, `descripcion`, `cantidadStock`, `fechaIngreso`, `unidadMedida`, `codigoProducto`, `state`, `id_proveedor`, `id_categoria`, `id_color`) VALUES
(17, 'Zocalo Superior Jumbo', 'Descripcion - Zocalo Superior Jumbo', 94, '2024-11-16', 'Cromo', 'A97', 1, 5, 1, 2),
(18, 'Zocalo Inferior Jumbo', 'Descripcion - Zocalo Inferior Jumbo', 0, '2024-11-16', 'Cromado', 'A98', 1, 5, 1, 2),
(19, 'Buchata', 'Descripcion - Buchata', 6, '2024-11-16', 'Cromado', 'A63', 1, 5, 2, 4),
(20, 'Socalo Superior', 'Descripcion - Socalo Superior', 0, '2024-11-16', 'Cromado', 'A61', 1, 5, 1, 3),
(21, 'Socalo Inferior', 'Descripcion - Socalo Superior', 8, '2024-11-16', 'Cromado', 'A62', 1, 5, 1, 1),
(22, 'Pivote Loco', 'Descripcion - Pivote Loco', 0, '2024-11-16', 'Cromado', 'A60', 1, 5, 3, 4),
(23, 'nuevo producto de prueba', 'cualquier cosas de descripcion', 0, '2025-01-16', 'Sin color', '7777', 1, 6, 2, 3),
(24, 'Producto A', 'Descripción del producto', 0, '2024-12-15', 'Unidad', 'CÓDIGO123', 1, 7, 1, 1),
(25, 'product x', 'xxx', 0, '2025-01-01', 'Plancha', 'micode', 1, 7, 1, 2),
(26, 'kokok', '3mn23n.,. 3jkl2jh', 0, '2025-01-09', 'asd', '90d', 1, 5, 2, 2),
(27, 'my product', 'descripcion del producto', 0, '2025-01-19', 'Unidad', '32d', 1, 5, 1, 1);

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

--
-- Dumping data for table `proveedor`
--

INSERT INTO `proveedor` (`id`, `empresa`, `nit`, `telefonoEmpresa`, `direccionEmpresa`, `id_persona`) VALUES
(5, 'Aluminios Mega Alum', '1111111111', '70735036', 'sin direccion de empresa por el momento', 6),
(6, 'Sandy Vid', '2222222222', '70721528', 'sin direccion de empresa sandy vid, cochabamba', 7),
(7, 'Renhua Boshi Aluminum Industry Co., Ltd', '3333333333', '591 72398702', 'AV. LAS BANDERAS #34 ZONA NUEVA TERMINAL,POTOSÍ BOLIVIA', 8);

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

--
-- Dumping data for table `usuario`
--

INSERT INTO `usuario` (`id`, `username`, `passwordHash`, `rol`, `estado`, `fechaCreacion`, `id_empleado`) VALUES
(5, 'lidia', '$2b$10$nBQrx8.aVHadaPc59YtfU.7lEe1cdWjduHWVIxRLCxVg2/29XO33e', 'admin', 'activo', '2025-01-16 01:26:40', 5),
(6, 'hernanfr', '$2b$10$pHfdOL7ZKKr/HbqzDrVyjuIujwUGb/8tcrmm9vJMJIUczCa/Hgfie', 'user', 'activo', '2025-01-16 01:30:50', 6);

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
  `id_empleado` bigint(20) UNSIGNED DEFAULT NULL,
  `confactura` tinyint(4) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `venta`
--

INSERT INTO `venta` (`id`, `fechaVenta`, `total`, `tokenSIM`, `id_cliente`, `id_empleado`, `confactura`) VALUES
(73, '2025-01-27', 595.00, 'tokenSIM', 2, 5, 1);

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
-- Indexes for table `color`
--
ALTER TABLE `color`
  ADD PRIMARY KEY (`id`);

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
  ADD KEY `FK_e87a319f3da1b6da5fedd1988be` (`id_categoria`),
  ADD KEY `FK_853dd0bfbe7c5d10cbc0447a2f8` (`id_color`);

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `categoria`
--
ALTER TABLE `categoria`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `cliente`
--
ALTER TABLE `cliente`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `color`
--
ALTER TABLE `color`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=202;

--
-- AUTO_INCREMENT for table `detalle_compra`
--
ALTER TABLE `detalle_compra`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=219;

--
-- AUTO_INCREMENT for table `detalle_venta`
--
ALTER TABLE `detalle_venta`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=70;

--
-- AUTO_INCREMENT for table `empleado`
--
ALTER TABLE `empleado`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `inventario`
--
ALTER TABLE `inventario`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=63;

--
-- AUTO_INCREMENT for table `lote_producto`
--
ALTER TABLE `lote_producto`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=88;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- AUTO_INCREMENT for table `producto`
--
ALTER TABLE `producto`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT for table `proveedor`
--
ALTER TABLE `proveedor`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `servicio`
--
ALTER TABLE `servicio`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `usuario`
--
ALTER TABLE `usuario`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `venta`
--
ALTER TABLE `venta`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=74;

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
  ADD CONSTRAINT `FK_853dd0bfbe7c5d10cbc0447a2f8` FOREIGN KEY (`id_color`) REFERENCES `color` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
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
