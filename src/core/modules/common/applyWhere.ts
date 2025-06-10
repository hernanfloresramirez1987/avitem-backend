import { MatchModel } from 'src/core/models/core.MatchModel';
import { Repository } from 'typeorm';

type FilterCondition = {
    value: any;
    matchMode: string;
};
type Filter = {
    [field: string]: FilterCondition;
};

import { Like, LessThanOrEqual, MoreThanOrEqual, Not, In } from 'typeorm';

export async function applyWhere(filter: Filter, repository: Repository<any>): Promise<any> {
  const where: any = {};

  for (const [field, condition] of Object.entries(filter)) {
    if (condition && condition.value != null && condition.value !== '') {
      switch (condition.matchMode) {
        case 'lte':
          where[field] = LessThanOrEqual(condition.value);
          break;
        case 'gte':
          where[field] = MoreThanOrEqual(condition.value);
          break;
        case 'contains':
          where[field] = Like(`%${condition.value}%`);
          break;
        case 'notEquals':
          where[field] = Not(condition.value);
          break;
        case 'in':
          where[field] = In(condition.value);
          break;
        default:
          where[field] = condition.value;
          break;
      }
    }
  }

  return where;
}