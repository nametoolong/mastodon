# frozen_string_literal: true

class ActivityPub::CollectionSerializer < ActivityPub::Serializer
  serialize :type

  show_if ->(model) { model.id.present? } do
    serialize :id
  end

  show_if ->(model) { model.size.present? } do
    serialize :totalItems, from: :size
  end

  show_if ->(model) { model.next.present? } do
    serialize :next
  end

  show_if ->(model) { model.prev.present? } do
    serialize :prev
  end

  show_if ->(model) { model.part_of.present? } do
    serialize :partOf, from: :part_of
  end

  show_if ->(model) { model.first.present? } do
    show_if ->(model) { model.first.is_a?(ActivityPub::CollectionPresenter) } do
      serialize :first, with: ActivityPub::CollectionSerializer, collection: false
    end

    show_if ->(model) { !model.first.is_a?(ActivityPub::CollectionPresenter) } do
      serialize :first
    end
  end

  show_if ->(model) { model.last.present? } do
    show_if ->(model) { model.last.is_a?(ActivityPub::CollectionPresenter) } do
      serialize :last, with: ActivityPub::CollectionSerializer, collection: false
    end

    show_if ->(model) { !model.last.is_a?(ActivityPub::CollectionPresenter) } do
      serialize :last
    end
  end

  show_if :has_item? do
    show_if :ordered? do
      serialize :orderedItems, from: :items
    end

    show_if :unordered? do
      serialize :items
    end
  end

  def type
    if page?
      ordered? ? 'OrderedCollectionPage' : 'CollectionPage'
    else
      ordered? ? 'OrderedCollection' : 'Collection'
    end
  end

  def ordered?
    model.type == :ordered
  end

  def unordered?
    !ordered?
  end

  def page?
    model.part_of.present? || model.page.present?
  end

  def has_item?
    !model.items.nil? || page?
  end
end
