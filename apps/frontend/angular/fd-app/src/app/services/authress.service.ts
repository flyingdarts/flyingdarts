import { Injectable } from '@angular/core';
import { AuthenticateResponse, LoginClient } from '@mikepattyn/authress-angular';

import { BehaviorSubject, Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class AuthressService {
  private isLoggedInSubject: BehaviorSubject<boolean> = new BehaviorSubject<boolean>(false);

  public isLoggedIn$: Observable<boolean> = this.isLoggedInSubject.asObservable();

  constructor(private readonly loginClient: LoginClient) {
  }

  async isLoggedIn(): Promise<boolean> {
    // Check for override token cookie first (for testing purposes)
    const overrideToken = this.getOverrideToken();
    if (overrideToken) {
      try {
        // Validate the override token by parsing JWT and checking expiration
        const isValid = this.isValidJWT(overrideToken);
        if (isValid) {
          this.isLoggedInSubject.next(true);
          return true;
        }
      } catch (error) {
        console.warn('[AuthressService] Override token validation failed:', error);
      }
    }

    // Fall back to normal Authress session check
    const loggedIn = await this.loginClient.userSessionExists();
    this.isLoggedInSubject.next(loggedIn);
    return loggedIn;
  }

  async authenticate(): Promise<AuthenticateResponse | null> {
    // Check if this is a first-time login by looking for existing session
    const isFirstTimeLogin = !await this.hasExistingSession();
    const redirectUrl = isFirstTimeLogin 
      ? 'https://game.flyingdarts.net' 
      : window.location.href;
    
    const response = await this.loginClient.authenticate({
      redirectUrl: redirectUrl,
    });
    this.isLoggedInSubject.next(response !== null);
    return response;
  }

  async getToken(): Promise<string> {
    const accessTokenOverride = document.cookie.split(';').map(c => c.split('=')).find(c => c[0] === 'custom-jwt-token-override')?.[1];
    if (accessTokenOverride) {
      return accessTokenOverride;
    }
    const token = await this.loginClient.ensureToken();
    return token;
  }

  async getUserName(): Promise<string | null> {
    const token = await this.getToken();
    const name = this.getName(token);
    return name;
  }

  async getUserId(): Promise<string> {
    // Check for override token first
    const overrideToken = this.getOverrideToken();
    if (overrideToken) {
      try {
        const userId = this.getUserIdFromToken(overrideToken);
        if (userId) {
          return userId;
        }
      } catch (error) {
        console.warn('[AuthressService] Failed to get user ID from override token:', error);
      }
    }

    // Fall back to normal Authress flow
    var userIdentity = this.loginClient.getUserIdentity();
    var userId: string = userIdentity['userId'] as string;
    return userId;
  }

  public async signout(redirectUrl: string): Promise<void> {
    await this.loginClient.logout(redirectUrl);
    this.isLoggedInSubject.next(false);
  }

  private getName(token: string | null): string | null {
    try {
      // Split the token into its parts
      const parts = token?.split('.');
      if (parts && parts.length !== 3) {
        throw new Error('Invalid JWT token');
      }

      // Decode the payload part of the token
      const payloadBase64 = parts![1].replace(/-/g, '+').replace(/_/g, '/');
      const payloadJson = atob(payloadBase64);
      const payload = JSON.parse(payloadJson);
      // Return the 'name' property if it exists
      const name = payload.name || null;
      return name;
    } catch (error) {
      console.error('[AuthressService] Failed to decode JWT:', error);
      return null;
    }
  }

  private getOverrideToken(): string | null {
    // Check for the override token cookie
    const cookies = document.cookie.split(';');
    const overrideCookie = cookies.find(cookie =>
      cookie.trim().startsWith('custom-jwt-token-override=')
    );

    if (overrideCookie) {
      return overrideCookie.split('=')[1];
    }

    return null;
  }

  private isValidJWT(token: string): boolean {
    try {
      // Split the token into its parts
      const parts = token.split('.');
      if (parts.length !== 3) {
        return false;
      }

      // Decode the payload (second part)
      const payload = parts[1];
      const base64 = payload.replace(/-/g, '+').replace(/_/g, '/');
      const jsonPayload = decodeURIComponent(
        atob(base64)
          .split('')
          .map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
          .join('')
      );

      const claims = JSON.parse(jsonPayload);

      // Check if token has expired
      if (claims.exp) {
        const currentTime = Math.floor(Date.now() / 1000); // Convert to whole seconds to match JWT exp format
        if (currentTime > claims.exp) {
          return false;
        }
      }

      // Check if token has required claims
      if (!claims.sub) {
        return false;
      }

      return true;
    } catch (error) {
      console.error('[AuthressService] Error validating override token:', error);
      return false;
    }
  }

  private getUserIdFromToken(token: string): string | null {
    try {
      // Split the token into its parts
      const parts = token.split('.');
      if (parts.length !== 3) {
        return null;
      }

      // Decode the payload (second part)
      const payload = parts[1];
      const base64 = payload.replace(/-/g, '+').replace(/_/g, '/');
      const jsonPayload = decodeURIComponent(
        atob(base64)
          .split('')
          .map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
          .join('')
      );

      const claims = JSON.parse(jsonPayload);

      // Return the 'sub' claim which contains the user ID
      return claims.sub || null;
    } catch (error) {
      console.error('[AuthressService] Failed to extract user ID from token:', error);
      return null;
    }
  }

  private async hasExistingSession(): Promise<boolean> {
    try {
      // Check for override token first
      const overrideToken = this.getOverrideToken();
      if (overrideToken && this.isValidJWT(overrideToken)) {
        return true;
      }

      // Check for Authress session
      const hasSession = await this.loginClient.userSessionExists();
      return hasSession;
    } catch (error) {
      console.error('[AuthressService] Error checking existing session:', error);
      return false;
    }
  }
}
