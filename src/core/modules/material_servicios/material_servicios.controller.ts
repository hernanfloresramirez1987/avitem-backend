import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { MaterialServiciosService } from './material_servicios.service';
import { CreateMaterialServicioDto } from './dto/create-material_servicio.dto';
import { UpdateMaterialServicioDto } from './dto/update-material_servicio.dto';

@Controller('material-servicios')
export class MaterialServiciosController {
  constructor(private readonly materialServiciosService: MaterialServiciosService) {}

  @Post()
  create(@Body() createMaterialServicioDto: CreateMaterialServicioDto) {
    return this.materialServiciosService.create(createMaterialServicioDto);
  }

  @Get()
  findAll() {
    return this.materialServiciosService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.materialServiciosService.findOne(+id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateMaterialServicioDto: UpdateMaterialServicioDto) {
    return this.materialServiciosService.update(+id, updateMaterialServicioDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.materialServiciosService.remove(+id);
  }
}
