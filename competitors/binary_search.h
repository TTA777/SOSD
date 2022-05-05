#pragma once

#include "base.h"

template <class KeyType>
class BinarySearch : public Competitor {
 public:
  uint64_t Build(const std::vector<KeyValue<KeyType>>& data) {
    // Nothing else to do here as input data is already sorted.
    data_size = data.size();
    return 0;
  }

  SearchBound EqualityLookup(const KeyType lookup_key) const {
    return (SearchBound){0, data_size};
  }

  void Insert(const KeyValue<KeyType> keyValue) {
    util::fail("Attempted to use inserts on index where wrapper does not support");
  }

  std::string name() const { return "BinarySearch"; }

  std::size_t size() const { return 0; }

 private:
  size_t data_size;
};
