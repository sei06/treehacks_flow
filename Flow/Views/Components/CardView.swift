/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

//
// CardView.swift
//
// Reusable container component that provides consistent card styling throughout the app.
//

import SwiftUI

struct CardView<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    VStack(spacing: 0) {
      content
    }
    .background(AuraTheme.surface)
    .cornerRadius(12)
    .shadow(
      color: AuraTheme.cardShadow,
      radius: 3,
      x: 0,
      y: 1
    )
  }
}
