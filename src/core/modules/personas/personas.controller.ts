import { Controller, Get, Post, Body, Patch, Param, Delete } from '@nestjs/common';
import { PersonasService } from './personas.service';
import { CreatePersonaDto } from './dto/create-persona.dto';
import { UpdatePersonaDto } from './dto/update-persona.dto';
import { Personas } from './entities/persona.entity';

@Controller('personas')
export class PersonasController {
  constructor(private readonly personasService: PersonasService) {}
  

  @Post()
  create(@Body() createPersonaDto: CreatePersonaDto) {
    return this.personasService.create(createPersonaDto);
  }

  @Get('searchCI/:ci')
  findOneCI(@Param('ci') ci: number) {
    return this.personasService.findOneCI(ci);
  }

  @Get()
  async findAll(): Promise<Personas[]> {
    return this.personasService.getAll(); // Devuelve todas las personas
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.personasService.findOne(+id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updatePersonaDto: UpdatePersonaDto) {
    return this.personasService.update(+id, updatePersonaDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.personasService.remove(+id);
  }
}
