#ifndef SOSDB_PGM_H
#define SOSDB_PGM_H

#include <algorithm>
#include <cstdlib>
#include <iostream>
#include <vector>

#include "../util.h"
#include "base.h"
#include "pgm_index_dynamic.hpp"
//#include <functional>
//#include <boost/iterator/transform_iterator.hpp>
//#include <boost/range/adaptors.hpp>

template <class KeyType, int pgm_error>
class PGM : public Competitor {
 public:
  uint64_t Build(const std::vector<KeyValue<KeyType>>& data) {

    std::vector<std::pair<KeyType, uint64_t>> kvPairs;
    kvPairs.reserve(data.size());
    for (KeyValue<KeyType> kv : data) {
      const auto key = kv.key;
      const auto value = kv.value;
      kvPairs.push_back(std::make_pair(key, value));
    }

    data_size_ = data.size();

    uint64_t build_time =
        util::timing([&] { pgm_ = decltype(pgm_)(kvPairs.begin(), kvPairs.end()); });

    return build_time;
  }

  SearchBound EqualityLookup(const KeyType lookup_key) const {
    auto it = pgm_.lower_bound(lookup_key);

    uint64_t guess;
    if (it == pgm_.cend()) {
      guess = data_size_ - 1;
    } else {
      guess = it.payload();
    }

    const uint64_t error = pgm_error;

    const uint64_t start = guess < error ? 0 : guess - error;
    const uint64_t stop = guess + 1 > data_size_
                          ? data_size_
                          : guess + 1;  // stop is exclusive (that's why +1)

    auto foundItem = pgm_.find(lookup_key);

    return (SearchBound){start, stop};
  }

  void Insert(const KeyValue<KeyType> keyValue) {
    pgm_.insert(keyValue.key, keyValue.value);
  }

  std::string name() const { return "PGM"; }

  std::size_t size() const { return pgm_.size_in_bytes(); }

  bool applicable(bool unique, const std::string& data_filename) const {
    return true;
  }

  int variant() const { return pgm_error; }

 private:
  uint64_t data_size_ = 0;
  DynamicPGMIndex<KeyType, uint64_t, PGMIndex<KeyType, pgm_error, 4>, 18> pgm_;
};

#endif  // SOSDB_PGM_H
