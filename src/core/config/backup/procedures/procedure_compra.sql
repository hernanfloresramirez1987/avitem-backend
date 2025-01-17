DROP PROCEDURE IF EXISTS registro_compra;
DELIMITER //

CREATE PROCEDURE registro_compra(
    IN p_idProveedor BIGINT,
    IN p_fechaCompra DATE,
    IN p_montoTotal DECIMAL(10,2),
    OUT p_idCompra INT,
    OUT p_resultado VARCHAR(100),
    OUT p_status INT
)
BEGIN
    DECLARE v_id_compra INT;

    -- Manejo de excepciones
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'Error: No se pudo completar el registro. Transacción revertida.';
        SET p_status = 400;
    END;

    START TRANSACTION;

    -- Inserción de la compra
    INSERT INTO compra (id_proveedor, fechaCompra, total)
    VALUES (p_idProveedor, p_fechaCompra, p_montoTotal);

    -- Obtener el último id insertado (id de la compra)
    SET v_id_compra = LAST_INSERT_ID();

    IF v_id_compra > 0 THEN
        SET p_idCompra = v_id_compra;  -- Se devuelve el ID de la compra para usarlo en detalles
        SET p_resultado = 'Compra registrada exitosamente.';
        SET p_status = 201;
        COMMIT;
    ELSE
        SET p_resultado = 'Error: No se pudo registrar la compra.';
        SET p_status = 400;
        ROLLBACK;
    END IF;
END //

DELIMITER ;