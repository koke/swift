//===--- Scope.h - Declarations for scope RAII objects ----------*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// This file defines the Scope and FullExpr RAII objects.
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_IRGEN_SCOPE_H
#define SWIFT_IRGEN_SCOPE_H

#include "IRGenFunction.h"

namespace swift {
namespace irgen {

/// A Scope is a RAII object recording that a scope (e.g. a brace
/// statement) has been entered.
class Scope {
  IRGenFunction &IGF;
  IRGenFunction::LocalTypeDataDepth SavedLocalTypeDataDepth;
  bool Popped;
public:
  explicit Scope(IRGenFunction &IGF)
    : IGF(IGF), SavedLocalTypeDataDepth(IGF.ScopedLocalTypeData.size()) {
      Popped = false;
  }

  void pop() {
    assert(!Popped);
    assert(IGF.ScopedLocalTypeData.size() >= SavedLocalTypeDataDepth);
    IGF.endLocalTypeDataScope(SavedLocalTypeDataDepth);
    Popped = true;
  }

  ~Scope() {
    if (!Popped)
      pop();
  }
};

} // end namespace irgen
} // end namespace swift

#endif
