import { Component } from '@angular/core';
import { Store } from '@ngrx/store';
import { AnimationOptions } from 'ngx-lottie';
import { Observable } from 'rxjs';
import { AppStateSelectors } from './state/app';
import { FriendsStateActions } from './state/friends';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
})
export class AppComponent {
  title = 'flyingdarts';
  appStateLoading$: Observable<boolean>;
  lottieOptions: AnimationOptions = {
    path: '/assets/animations/flyingdarts_icon.json',
  };

  constructor(private readonly store: Store) {
    this.appStateLoading$ = this.store.select(AppStateSelectors.selectLoading);
    this.store.dispatch(FriendsStateActions.loadFriends());
    this.store.dispatch(FriendsStateActions.loadFriendRequests());
  }
}
