DROP PROCEDURE IF EXISTS registro_producto;
DELIMITER //

CREATE PROCEDURE registro_producto (
    IN p_nombre VARCHAR(100),
    IN p_descripcion TEXT,
    IN p_cantidadStock INT,
    IN p_fechaIngreso DATE,
    IN p_unidadMedida VARCHAR(20),
    IN p_codigoProducto VARCHAR(50),
    IN p_idProveedor BIGINT,
    IN p_idCategoria BIGINT,
    IN p_state INT,
    OUT p_resultado VARCHAR(100),
    OUT p_status INT
)
BEGIN
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
            INSERT INTO producto (nombre,descripcion,cantidadStock,fechaIngreso,unidadMedida,codigoProducto,idProveedor,idCategoria,state)
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
END //

DELIMITER ;