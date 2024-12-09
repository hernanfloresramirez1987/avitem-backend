import { Module } from '@nestjs/common';
import { TransaccionContablesService } from './transaccion_contables.service';
import { TransaccionContablesController } from './transaccion_contables.controller';

@Module({
  controllers: [TransaccionContablesController],
  providers: [TransaccionContablesService],
})
export class TransaccionContablesModule {}
