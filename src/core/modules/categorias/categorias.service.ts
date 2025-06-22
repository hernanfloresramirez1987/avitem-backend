import { Injectable } from '@nestjs/common';
import { CreateCategoriaDto } from './dto/create-categoria.dto';
import { UpdateCategoriaDto } from './dto/update-categoria.dto';
import { InjectRepository } from '@nestjs/typeorm';
import { Categorias } from './entities/categoria.entity';
import { Connection, Repository } from 'typeorm';

@Injectable()
export class CategoriasService {

  constructor(
    @InjectRepository(Categorias)
    private readonly categoriaRepository: Repository<Categorias>,
    private readonly connection: Connection
  ) {}

  async create(createCategoriaDto: CreateCategoriaDto): Promise<Categorias> {
    const categoria = this.categoriaRepository.create(createCategoriaDto);
    return this.categoriaRepository.save(categoria);
  }

  async findAll(): Promise<Categorias[]> {
    return await this.categoriaRepository.find();
  }

  findOneID(iddto: number) {
    return this.categoriaRepository.find({ where: { id: iddto } });
  }
  
  findOne(id: number) {
    return `This action returns a #${id} categoria`;
  }

  update(id: number, updateCategoriaDto: UpdateCategoriaDto) {
    return `This action updates a #${id} categoria`;
  }

  remove(id: number) {
    return `This action removes a #${id} categoria`;
  }
}
