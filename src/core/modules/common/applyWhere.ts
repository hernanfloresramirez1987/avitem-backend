import { MatchModel } from 'src/core/models/core.MatchModel';
import { Repository } from 'typeorm';

export async function applyWhere(
  matchModel: MatchModel,
  campo: string,
  repository: Repository<any>
): Promise<any[]> {
  let queryBuilder = repository.createQueryBuilder();

  if (matchModel.value != null && matchModel.value !== '') {
    let operator = '';
    let value = matchModel.value;

    switch (matchModel.matchMode) {
      case 'lte':
        operator = '<=';
        break;
      case 'gte':
        operator = '>=';
        break;
      case 'contains':
        operator = 'LIKE';
        value = `%${value}%`; // SQL LIKE syntax
        break;
      case 'notEquals':
        operator = '!=';
        break;
      case 'isNot':
        operator = 'IS NOT';
        break;
      case 'in':
        if (Array.isArray(value) && value.length > 0) {
          operator = 'IN';
          queryBuilder.where(`${campo} ${operator} (:...value)`, { value });
          return queryBuilder.getMany();
        }
        operator = '=';
        break;
      default:
        operator = '=';
        break;
    }

    queryBuilder.where(`${campo} ${operator} :value`, { value });
  }

  return queryBuilder.getMany();
}