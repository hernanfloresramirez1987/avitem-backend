import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { UsuariosService } from './usuarios.service';
import { CreateUsuarioDto } from './dto/create-usuario.dto';
import { UpdateUsuarioDto } from './dto/update-usuario.dto';
import { Proveedores } from '../proveedores/entities/proveedore.entity';
import { ProveedorRepository } from 'src/core/shared/repositories/ProveedorRep';
import { InjectRepository } from '@nestjs/typeorm';
import { Connection } from 'typeorm';

@Controller('usuarios')
export class UsuariosController {
  // constructor(private readonly usuariosService: UsuariosService) {}
  constructor(
    @InjectRepository(Proveedores)
    private readonly empleadosRepository: ProveedorRepository,
    private readonly usuariosService: UsuariosService,
    private readonly connection: Connection
  ) {}

  @Post()
  create(@Body() createUsuarioDto: CreateUsuarioDto) {
    return this.usuariosService.create(createUsuarioDto);
  }

  @Get()
  findAll() {
    return this.usuariosService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.usuariosService.findOne(+id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateUsuarioDto: UpdateUsuarioDto) {
    return this.usuariosService.update(+id, updateUsuarioDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.usuariosService.remove(+id);
  }
}
