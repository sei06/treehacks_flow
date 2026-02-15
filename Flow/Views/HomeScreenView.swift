/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

//
// HomeScreenView.swift
//
// Welcome screen that guides users through the DAT SDK registration process.
// This view is displayed when the app is not yet registered.
//

import MWDATCore
import SwiftUI

struct HomeScreenView: View {
  @ObservedObject var viewModel: WearablesViewModel

  var body: some View {
    ZStack {
      AuraTheme.bg.ignoresSafeArea()

      VStack(spacing: 20) {
        Spacer()

        Image(.cameraAccessIcon)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 100)
          .shadow(color: AuraTheme.artShadow, radius: 20)

        Text("flow")
          .font(AuraFont.brand(32))
          .foregroundColor(AuraTheme.textPrimary)

        // Feature list card
        VStack(spacing: 0) {
          HomeTipItemView(
            resource: .smartGlassesIcon,
            title: "Video Capture",
            text: "Record videos directly from your glasses, from your point of view."
          )
          Divider().background(AuraTheme.border).padding(.horizontal, 16)
          HomeTipItemView(
            resource: .soundIcon,
            title: "Open-Ear Audio",
            text: "Hear notifications while keeping your ears open to the world around you."
          )
          Divider().background(AuraTheme.border).padding(.horizontal, 16)
          HomeTipItemView(
            resource: .walkingIcon,
            title: "Enjoy On-the-Go",
            text: "Stay hands-free while you move through your day."
          )
        }
        .padding(.vertical, 16)
        .auraCard(cornerRadius: 20)

        Spacer()

        // Bottom connect section
        VStack(spacing: 16) {
          Text("You'll be redirected to the Meta AI app to confirm your connection.")
            .font(.system(size: 14))
            .foregroundColor(AuraTheme.textSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)

          Button(action: { viewModel.connectGlasses() }) {
            Text(viewModel.registrationState == .registering ? "Connecting..." : "Connect my glasses")
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .frame(height: 56)
              .background(
                RoundedRectangle(cornerRadius: 28)
                  .fill(AuraTheme.accent)
              )
          }
          .disabled(viewModel.registrationState == .registering)
          .opacity(viewModel.registrationState == .registering ? 0.6 : 1.0)
        }
      }
      .padding(.all, 24)
    }
  }
}

struct HomeTipItemView: View {
  let resource: ImageResource
  let title: String
  let text: String

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(resource)
        .resizable()
        .renderingMode(.template)
        .foregroundColor(AuraTheme.accent)
        .aspectRatio(contentMode: .fit)
        .frame(width: 24)
        .padding(.leading, 16)
        .padding(.top, 4)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.system(size: 17, weight: .semibold))
          .foregroundColor(AuraTheme.textPrimary)

        Text(text)
          .font(.system(size: 14))
          .foregroundColor(AuraTheme.textSecondary)
      }
      Spacer()
    }
    .padding(.vertical, 12)
    .padding(.trailing, 16)
  }
}
