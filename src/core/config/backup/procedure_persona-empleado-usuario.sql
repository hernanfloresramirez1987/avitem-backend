DROP PROCEDURE IF EXISTS registro_persona_empleado;
DELIMITER //

CREATE PROCEDURE registro_persona_empleado (
    IN u_username VARCHAR(100),
    IN u_password VARCHAR(255),
    IN u_rol ENUM('admin','user','guest'),
    
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
    
    IN e_idtipo BIGINT,
    IN e_idcargo BIGINT,
    IN e_fing VARCHAR(255),
    IN e_salario INT,
    OUT p_resultado VARCHAR(100),
    OUT p_status INT
)
BEGIN
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

        -- Insertar persona
        INSERT INTO persona (
            ci, ciExpedit, ciComplement, nombre, app, apm, 
            sexo, fnaci, direccion, telefono, email, state
        )
        VALUES (
            p_ci, p_ciExpedit, p_ciComplement, p_nombre, p_app, p_apm,
            p_sexo, p_fnaci, p_direccion, p_telefono, p_email, 1
        );

        SET v_id_persona = LAST_INSERT_ID();

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
END //

DELIMITER ;









-- 
CALL registro_persona_empleado(
    -- Datos de usuario 3
    'juan.perez',                    -- username
    '$2a$10$xxxxxxxxxxx',            -- password hash (ejemplo de hash bcrypt)
    'user',                          -- rol (admin/user/guest)
    
    -- Datos de persona 11
    '123456',                        -- CI
    'LP',                           -- Expedido en (LP, SC, CB, etc.)
    0,                              -- Complemento CI
    'Juan',                         -- Nombre
    'Perez',                        -- Apellido paterno
    'Gomez',                        -- Apellido materno
    'M',                            -- Sexo (M/F)
    '1990-01-01',                   -- Fecha nacimiento
    'Av. 6 de Agosto #123',         -- Dirección
    '71234567',                     -- Teléfono
    'juan.perez@email.com',         -- Email
    
    -- Datos de empleado 4
    1,                              -- idtipo (ID del tipo de empleado)
    2,                              -- idcargo (ID del cargo)
    '2024-01-15',                   -- Fecha de ingreso
    3500,                           -- Salario
    
    -- Variables de salida 2
    @resultado,                     -- Variable para el mensaje de resultado
    @status                         -- Variable para el código de estado
);

-- Verificar el resultado
SELECT @resultado AS Mensaje, @status AS CodigoEstado;
