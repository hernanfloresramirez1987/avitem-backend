import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { ClientesService } from './clientes.service';
import { CreateClienteDto } from './dto/create-cliente.dto';
import { UpdateClienteDto } from './dto/update-cliente.dto';

@Controller('clientes')
export class ClientesController {
  constructor(private readonly clientesService: ClientesService) {}

  @Post()
  create(@Body() createClienteDto: CreateClienteDto) {
    return this.clientesService.create(createClienteDto);
  }

  @Post('register')
  saveEmp(@Body() createClientDto: any) {
    return this.clientesService.saveCliente(createClientDto);
  }

  @Post('list')
  findAllFilter(@Body() filter: any) {
    return this.clientesService.findAll();
  }

  @Get()
  findAll() {
    return this.clientesService.findAll();
  }

  @Get('searchCI/:ci')
  findOneCI(@Param('ci') id: string) {
    return this.clientesService.findOneCI(Number(id));
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.clientesService.findOne(+id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateClienteDto: UpdateClienteDto) {
    return this.clientesService.update(+id, updateClienteDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.clientesService.remove(+id);
  }
}
