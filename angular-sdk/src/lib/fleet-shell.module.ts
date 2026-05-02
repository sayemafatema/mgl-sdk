import { CommonModule } from '@angular/common';
import { NgModule } from '@angular/core';
import { RouterModule } from '@angular/router';
import { FleetFlowHostComponent } from './fleet-flow-host.component';
import { FLEET_SHELL_ROUTES } from './fleet-shell.routes';

/** Lazy-load once — hosts full login/signup → driver app (matches React demo flow). */
@NgModule({
  imports: [CommonModule, RouterModule.forChild(FLEET_SHELL_ROUTES)],
  declarations: [FleetFlowHostComponent],
})
export class FleetShellModule {}
