DROP PROCEDURE IF EXISTS registro_persona_empleado;
DELIMITER //
CREATE PROCEDURE registro_persona_empleado (
   IN u_name VARCHAR(20),
   IN u_password VARCHAR(255),
   IN u_rol INT,
  
   IN p_doc VARCHAR(25),
   IN p_tipodoc INT,
   IN p_extdoc INT,
   IN p_nombre VARCHAR(100),
   IN p_app VARCHAR(150),
   IN p_apm VARCHAR(150),
   IN p_fnaci DATE,
   IN p_sexo TINYINT(1),
   IN p_estadociv VARCHAR(20),
   IN p_dir VARCHAR(250),
   IN p_telcel VARCHAR(20),
   IN p_email VARCHAR(250),
  
   IN e_idtipo INT,
   IN e_idcargo INT,
   IN e_fing DATE,
   IN e_salario INT,
   OUT p_resultado VARCHAR(100),
   OUT p_status INT
)
BEGIN
   DECLARE v_error_code INT DEFAULT 0;
   DECLARE v_id_persona INT;
   DECLARE v_id_user INT;


   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       ROLLBACK;
       SELECT 'Error: No se pudo insertar al personal. Transacción revertida.' AS Mensaje;
   END;
  
   -- Verificar si ya existe un usuario con el nombre proporcionado
   SELECT id INTO v_id_user FROM user WHERE name = u_name;
   -- Si ya existe un usuario con ese nombre, enviar un mensaje de error
   IF v_id_user IS NOT NULL THEN
       SET p_resultado = 'Error: Ya existe un usuario con ese nombre.';
       SET p_status = 400;
       ROLLBACK;
   ELSE


       START TRANSACTION;
       -- Buscar si existe la persona por el documento
       SELECT id INTO v_id_persona FROM persona WHERE doc = p_doc;
  
       -- Si se encontró una persona, actualizar los datos
       IF v_id_persona IS NOT NULL THEN
           UPDATE persona
           SET
               tipodoc = p_tipodoc,
               extdoc = p_extdoc,
               nombre = p_nombre,
               app = p_app,
               apm = p_apm,
               fnaci = p_fnaci,
               sexo = p_sexo,
               estadociv = p_estadociv,
               dir = p_dir,
               telcel = p_telcel,
               email = p_email
           WHERE id = v_id_persona;
       ELSE
           -- Si no se encontró la persona, insertar un nuevo registro
           INSERT INTO persona (doc, tipodoc, extdoc, nombre, app, apm, fnaci, sexo, estadociv, dir, telcel, email)
           VALUES (p_doc, p_tipodoc, p_extdoc, p_nombre, p_app, p_apm, p_fnaci, p_sexo, p_estadociv, p_dir, p_telcel, p_email);
           -- Obtener el ID de la persona insertada
           SET v_id_persona = LAST_INSERT_ID();
       END IF;


       INSERT INTO user (name, password, role, state)
       VALUES (u_name, u_password, u_rol, 1);


       SET v_id_user = LAST_INSERT_ID();
      
       INSERT INTO empleado (id, idper, idtipo, idcargo, fing, salario)
       VALUES (v_id_user, v_id_persona, e_idtipo, e_idcargo, e_fing, e_salario);
      
       INSERT INTO rolesasignados (iduser, idrol)
       VALUES (v_id_user, u_rol);
      
       IF ROW_COUNT() > 0 THEN
           SET p_resultado = 'OK';
           SET p_status = 201;
       ELSE
           SET v_error_code = -1;
           SET p_status = 400;
           SET p_resultado = 'Error: No se pudo insertar el usuario.';
       END IF;
       COMMIT;
   END IF;
  
  
END //
DELIMITER ;
