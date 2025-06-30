DROP PROCEDURE IF EXISTS registrar_venta_y_descuento;
DELIMITER //


CREATE PROCEDURE registrar_venta_y_descuento(
    IN p_fechaVenta DATE,
    IN p_total DECIMAL(10,2),
    IN p_id_cliente BIGINT(20),
    IN p_id_empleado BIGINT(20),
    IN p_tokenSIN BIGINT(20),
    IN p_detalle JSON,
    OUT p_resultado VARCHAR(100),
    OUT p_status INT)


main_block: BEGIN  -- Añadida etiqueta al bloque principal
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
  SET p_id_venta = v_id_venta;
  SET p_status = 200;
END //
DELIMITER ;
