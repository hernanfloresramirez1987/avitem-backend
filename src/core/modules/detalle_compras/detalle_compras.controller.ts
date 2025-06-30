import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { DetalleComprasService } from './detalle_compras.service';
import { CreateDetalleCompraDto } from './dto/create-detalle_compra.dto';
import { UpdateDetalleCompraDto } from './dto/update-detalle_compra.dto';

@Controller('detalle-compras')
export class DetalleComprasController {
  constructor(private readonly detalleComprasService: DetalleComprasService) {}

  @Post()
  create(@Body() createDetalleCompraDto: CreateDetalleCompraDto) {
    return this.detalleComprasService.create(createDetalleCompraDto);
  }

  @Get()
  findAll() {
    return this.detalleComprasService.findAll();
  }

  @Get('items/:id')
  findAllOne(@Param('id') id: string) {
    return this.detalleComprasService.findAllOne(+id);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.detalleComprasService.findOne(+id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateDetalleCompraDto: UpdateDetalleCompraDto) {
    return this.detalleComprasService.update(+id, updateDetalleCompraDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.detalleComprasService.remove(+id);
  }
}
