import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { OrdenServiciosService } from './orden_servicios.service';
import { CreateOrdenServicioDto } from './dto/create-orden_servicio.dto';
import { UpdateOrdenServicioDto } from './dto/update-orden_servicio.dto';

@Controller('orden-servicios')
export class OrdenServiciosController {
  constructor(private readonly ordenServiciosService: OrdenServiciosService) {}

  @Post()
  create(@Body() createOrdenServicioDto: CreateOrdenServicioDto) {
    return this.ordenServiciosService.create(createOrdenServicioDto);
  }

  @Get()
  findAll() {
    return this.ordenServiciosService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.ordenServiciosService.findOne(+id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateOrdenServicioDto: UpdateOrdenServicioDto) {
    return this.ordenServiciosService.update(+id, updateOrdenServicioDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.ordenServiciosService.remove(+id);
  }
}
