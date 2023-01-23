# frozen_string_literal: true

ActivityPub::CollectionPresenter = Struct.new(
  :id, :type, :size, :items, :page, :part_of, :first, :last, :next, :prev,
  keyword_init: true
)
