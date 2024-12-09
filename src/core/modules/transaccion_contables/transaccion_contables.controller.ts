import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { TransaccionContablesService } from './transaccion_contables.service';
import { CreateTransaccionContableDto } from './dto/create-transaccion_contable.dto';
import { UpdateTransaccionContableDto } from './dto/update-transaccion_contable.dto';

@Controller('transaccion-contables')
export class TransaccionContablesController {
  constructor(private readonly transaccionContablesService: TransaccionContablesService) {}

  @Post()
  create(@Body() createTransaccionContableDto: CreateTransaccionContableDto) {
    return this.transaccionContablesService.create(createTransaccionContableDto);
  }

  @Get()
  findAll() {
    return this.transaccionContablesService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.transaccionContablesService.findOne(+id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateTransaccionContableDto: UpdateTransaccionContableDto) {
    return this.transaccionContablesService.update(+id, updateTransaccionContableDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.transaccionContablesService.remove(+id);
  }
}
