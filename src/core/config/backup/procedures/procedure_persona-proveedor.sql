DROP PROCEDURE IF EXISTS registro_persona_proveedor;
DELIMITER //

CREATE PROCEDURE registro_persona_proveedor (
    IN p_ci VARCHAR(15), 
    IN p_ciExpedit VARCHAR(2),
    IN p_ciComplement INT,
    IN p_nombre VARCHAR(100),
    IN p_app VARCHAR(100),
    IN p_apm VARCHAR(100),
    IN p_sexo CHAR(1),
    IN p_fnaci DATE,
    IN p_direccion VARCHAR(200),
    IN p_telefono VARCHAR(15),
    IN p_email VARCHAR(100),

    IN pr_empresa VARCHAR(100),
    IN pr_nit VARCHAR(20),
    IN pr_telefonoEmpresa VARCHAR(15),
    IN pr_direccionEmpresa VARCHAR(200),
    OUT p_resultado VARCHAR(100),
    OUT p_status INT
)
BEGIN
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
END //

DELIMITER ;
