import { CommonModule } from '@angular/common';
import { Component, ElementRef, HostListener } from '@angular/core';
import { RouterModule } from '@angular/router';
import { Store } from '@ngrx/store';
import { map, Observable } from 'rxjs';
import { AuthressService } from 'src/app/services/authress.service';
import { AppStateActions, AppStateSelectors } from 'src/app/state/app';
import { ThemeTogglerComponent } from './components/theme-toggler/theme-toggler.component';

@Component({
  selector: 'app-navbar',
  imports: [CommonModule, RouterModule, ThemeTogglerComponent],
  templateUrl: './navbar.component.html',
  styleUrl: './navbar.component.scss',
  standalone: true,
})
// eslint-disable-next-line @typescript-eslint/no-extraneous-class
export class NavbarComponent {
  isLoggedIn$: Observable<boolean>;
  userName$: Observable<string>;
  userPicture$: Observable<string>;
  isDarkMode$: Observable<boolean>;
  mobileOpen = false;
  userMenuOpen = false;

  constructor(
    private readonly store: Store,
    private readonly authressService: AuthressService,
    private readonly elRef: ElementRef<HTMLElement>,
  ) {
    this.isLoggedIn$ = authressService.isLoggedIn$; // TODO: Move to state
    this.userName$ = store
      .select(AppStateSelectors.selectUserName)
      .pipe(map(name => (name == '' ? sessionStorage.getItem('userName')! : name)));
    this.userPicture$ = store.select(AppStateSelectors.selectUserPicture);
    this.isDarkMode$ = store.select(AppStateSelectors.selectThemeMode).pipe(map(mode => mode === 'dark'));
  }

  toggleMobile(): void {
    this.mobileOpen = !this.mobileOpen;
    if (!this.mobileOpen) {
      this.userMenuOpen = false;
    }
  }

  closeMobile(): void {
    this.mobileOpen = false;
    this.userMenuOpen = false;
  }

  toggleUserMenu(): void {
    this.userMenuOpen = !this.userMenuOpen;
  }

  closeUserMenu(): void {
    this.userMenuOpen = false;
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    if (!this.elRef.nativeElement.contains(event.target as Node)) {
      this.userMenuOpen = false;
      this.mobileOpen = false;
    }
  }

  logout() {
    this.closeMobile();
    this.closeUserMenu();
    this.store.dispatch(AppStateActions.setLoading({ loading: true }));
    this.store.dispatch(AppStateActions.setIdToken({ idToken: undefined }));
    this.store.dispatch(AppStateActions.setUser({ user: undefined }));
    this.authressService.signout(window.location.origin);
  }
}
