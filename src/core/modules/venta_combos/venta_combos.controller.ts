import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { VentaCombosService } from './venta_combos.service';
import { CreateVentaComboDto } from './dto/create-venta_combo.dto';
import { UpdateVentaComboDto } from './dto/update-venta_combo.dto';

@Controller('venta-combos')
export class VentaCombosController {
  constructor(private readonly ventaCombosService: VentaCombosService) {}

  @Post()
  create(@Body() createVentaComboDto: CreateVentaComboDto) {
    return this.ventaCombosService.create(createVentaComboDto);
  }

  @Get()
  findAll() {
    return this.ventaCombosService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.ventaCombosService.findOne(+id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateVentaComboDto: UpdateVentaComboDto) {
    return this.ventaCombosService.update(+id, updateVentaComboDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.ventaCombosService.remove(+id);
  }
}
