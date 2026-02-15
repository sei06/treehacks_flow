/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

//
// MainAppView.swift
//
// Central navigation hub that displays different views based on DAT SDK registration and device states.
// When unregistered, shows the registration flow. When registered, shows the device selection screen
// for choosing which Meta wearable device to stream from.
//

import MWDATCore
import SwiftUI

struct MainAppView: View {
  let wearables: WearablesInterface
  @ObservedObject private var viewModel: WearablesViewModel
  @State private var hasCompletedMusicTaste = false
  @State private var hasCompletedDemo = false

  private enum AppPhase {
    case onboarding
    case demo
    case main
  }

  private var currentPhase: AppPhase {
    if !hasCompletedMusicTaste { return .onboarding }
    if !hasCompletedDemo { return .demo }
    return .main
  }

  init(wearables: WearablesInterface, viewModel: WearablesViewModel) {
    self.wearables = wearables
    self.viewModel = viewModel
  }

  var body: some View {
    if viewModel.registrationState == .registered || viewModel.hasMockDevice {
      switch currentPhase {
      case .onboarding:
        OnboardingContainer {
          hasCompletedMusicTaste = true
        }
      case .demo:
        DemoContainer {
          hasCompletedDemo = true
        }
      case .main:
        StreamSessionView(wearables: wearables, wearablesVM: viewModel)
      }
    } else {
      HomeScreenView(viewModel: viewModel)
    }
  }
}
